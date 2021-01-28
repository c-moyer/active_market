class ActiveMarket::Amazon
  class Order < ActiveMarket::Amazon

    ORDER_STATUS = {
      "Unshipped" => "Processing",
      "PartiallyShipped" => "Processing",
      "Shipped" => "Complete",
      "Canceled" => "Cancelled",
      "Unfulfillable" => "Hold"
    }.freeze


    def initialize(creds, opts={})
      super
      @ftime = "%Y-%m-%dT%H:%M:%S.%LZ"
    end

    def get_orders(opts={})
      begin
      #init client
      client = get_client
      last_run_timestamp = nil
      if opts[:next_page]
        #get next page of orders
        response = client.list_orders_by_next_token(opts[:next_page])
      else
        #get orders by params
        response = client.list_orders('ATVPDKIKX0DER', last_updated_after: Time.parse(opts[:start_date]).strftime(@ftime), order_status: ["Unshipped", "PartiallyShipped", "Shipped", "Canceled", "Unfulfillable"])
      end

      response = response.parse

      if response.has_key?("LastUpdatedBefore")
        last_run_timestamp = DateTime.parse(response["LastUpdatedBefore"], @ftime)
      end

      #if response["Orders"] == nil
      #  break
      #end

      #if has token then set to next token else set to nil
      next_token = response.has_key?("NextToken") ? response["NextToken"] : nil

      if response["Orders"] != nil
        orders = parse_orders_response(response, client)
      end



        return ActiveMarket::Response.new(ActiveMarket::OrdersResult.new({orders: orders || [], next_page: next_token, end_date: last_run_timestamp}), {body: response, code: 200})
      rescue => e
        return ErrorHandler.new(ActiveMarket::ResponseError.new(e.message, {code: 500, secondary_type: e.class}))
      end


    end

    private

    def parse_items(response)
      #items
      items = response.parse

      if items.has_key?("NextToken")
        raise NotImplementedError
      end
      items = items["OrderItems"]["OrderItem"]

      if !items.is_a?(Array)
        items = [items]
      end

      tax = BigDecimal(0)
      shipping = BigDecimal(0)
      subtotal = BigDecimal(0)
      shipping_discount = BigDecimal(0)
      product_discount = BigDecimal(0)

      item_array = []

      items.each do |item|

        #init item_price to default to 0
        item_price = BigDecimal("0")

        #calculate totals
        if item.has_key?("ShippingTax")
          tax = (tax + BigDecimal(item["ShippingTax"]["Amount"])).round(2)
        end

        if item.has_key?("ShippingDiscountTax")
          tax = (tax + BigDecimal(item["ShippingDiscountTax"]["Amount"])).round(2)
        end

        if item.has_key?("ItemTax")
          tax = (tax + BigDecimal(item["ItemTax"]["Amount"])).round(2)
        end

        if item.has_key?("PromotionDiscountTax")
          tax = (tax + BigDecimal(item["PromotionDiscountTax"]["Amount"])).round(2)
        end

        if item.has_key?("ShippingPrice")
          shipping = (shipping + BigDecimal(item["ShippingPrice"]["Amount"])).round(2)
        end

        if item.has_key?("PromotionDiscount")
          product_discount = ( product_discount + BigDecimal(item["PromotionDiscount"]["Amount"]))
        end

        if item.has_key?("ShippingDiscount")
          shipping_discount = ( shipping_discount + BigDecimal(item["ShippingDiscount"]["Amount"]))
        end

        if item.has_key?("ItemPrice")
          #Note that an order item is an item and a quantity. This means that the
          #value of ItemPrice is equal to the selling price of the item multiplied
          #by the quantity ordered. Note that ItemPrice excludes ShippingPrice and GiftWrapPrice.

          if BigDecimal("#{item["QuantityOrdered"]}") > BigDecimal("0")
            item_price = (BigDecimal("#{item["ItemPrice"]["Amount"]}") / BigDecimal("#{item["QuantityOrdered"]}")).round(2)
          end
          subtotal = (subtotal + BigDecimal(item["ItemPrice"]["Amount"])).round(2)

        end

        #build array
        item_array << {
          name: item["Title"],
          sku: item["SellerSKU"],
          price: item_price,
          id: item["OrderItemId"],
          quantity: item["QuantityOrdered"]
        }

      end

      return {
        tax: tax,
        shipping: shipping,
        subtotal: subtotal,
        shipping_discount: shipping_discount,
        product_discount: product_discount,
        items: item_array
      }
    end

    def parse_orders_response(response, client)
      orders_response = response["Orders"]["Order"]
      if !orders_response.is_a?(Array)
        orders_response = [orders_response]
      end

      orders = []
      orders_response.each_with_index do |i, index|

        order = ActiveMarket::Order.new(marketplace: "Amazon")
        order.status = ORDER_STATUS[i["OrderStatus"]]
        order.created_at = DateTime.parse(i["PurchaseDate"], @ftime)
        order.ordered_at = DateTime.now
        order.order_number = i["AmazonOrderId"]
        order.shipping_method = i["ShipServiceLevel"]
        order.fulfillment_channel = i["FulfillmentChannel"]
        order.amazon_prime = i["IsPrime"]

        order.addresses << {
          type: "Shipping",
          email: i["BuyerEmail"],
          country: (i["ShippingAddress"]["CountryCode"] unless !i.has_key?("ShippingAddress")),
          state: (i["ShippingAddress"]["StateOrRegion"] unless !i.has_key?("ShippingAddress")),
          city: (i["ShippingAddress"]["City"] unless !i.has_key?("ShippingAddress")),
          postal_code: (i["ShippingAddress"]["PostalCode"] unless !i.has_key?("ShippingAddress"))
        }
        sleep(2)
        data = parse_items(
          client.list_order_items(i["AmazonOrderId"])
        )

        order.items = data[:items]

        subtotal = ( data[:subtotal] + data[:shipping] ).round(2)
        subtotal = ( subtotal - data[:shipping_discount] ).round(2)
        subtotal = ( subtotal - data[:product_discount] ).round(2)
        order.subtotal = subtotal
        order.shipping_discount = data[:shipping_discount]
        order.product_discount = data[:product_discount]
        order.tax = data[:tax]
        order.shipping = data[:shipping]
        order.grand_total = i.has_key?("OrderTotal") ? i["OrderTotal"]["Amount"] : BigDecimal(0)

        orders << order
      end
      return orders
    end
    def get_client
      client = MWS.orders(marketplace: @marketplace,
                          merchant_id: @merchant_id,
                          aws_access_key_id: @creds.client_id,
                          aws_secret_access_key: @creds.client_secret)
    end
  end
end
