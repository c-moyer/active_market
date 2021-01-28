class ActiveMarket::Ebay
  class Order < ActiveMarket::Ebay

    def initialize(creds)
      super(creds)
      @header = {
        'Content-Type' => 'application/json',
        #'Accept': 'application/json',
        'Authorization' => "Bearer #{@token}"
      }
    end


    SUCCESS_CODES = %w(200 201).freeze

    def get_orders(opts = {})

      if opts[:next_page]
        uri = URI.parse(opts[:next_page])
      else
        uri = URI.parse(@domain + "/sell/fulfillment/v1/order")
      end

      if opts[:next_page] == nil && opts[:start_date] != nil && opts[:end_date] != nil
        #only send params if next page is nil. Sending blank params hash will cause errors.
        #[YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z
        params = {
          'filter': "lastmodifieddate:%5B#{Time.parse(opts[:start_date]).strftime("%Y-%m-%dT%H:%M:%S.000Z")}..#{Time.parse(opts[:end_date]).strftime("%Y-%m-%dT%H:%M:%S.000Z")}%5D",
          #'limit': 1
        }
        uri.query = URI.encode_www_form(params)
      end

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, @header)

      # Send the request
      response = http.request(request)
      code = response.code
      success = response_success?(response)
      response = JSON.parse(response.body)
      orders = []
      if success
        orders = parse_orders_response(response)
      end

      #returns decorated response
      begin
        return ActiveMarket::Response.new(ActiveMarket::OrdersResult.new({orders: orders, next_page: response["next"]}), {body: response, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end

    end#end get_orders

    def create_shipment(shipment)

      uri = URI.parse(@domain + "/sell/fulfillment/v1/order/#{shipment.order_number}/shipping_fulfillment")
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      items = []
      shipment.items.each do |i|
        items << {"lineItemId": i.id}
      end
      params = {
        "lineItems": items,
        "shippedDate": shipment.created_at.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "shippingCarrierCode": shipment.carrier,
        "trackingNumber": shipment.tracking_number
      }

      request = Net::HTTP::Post.new(uri.request_uri, @header)
      request.body = params.to_json

      # Send the request
      response = http.request(request)

      begin
        return ActiveMarket::Response.new(ActiveMarket::CreateShipmentResult.new, {body: (JSON.parse(response.body) unless response.body.empty?) || nil, code: response.code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    def get_shipments(order_id)
      uri = URI.parse("https://api.ebay.com/sell/fulfillment/v1/order/#{order_id}/shipping_fulfillment")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri, @header)
      response = http.request(request)

      body = JSON.parse(response.body)

      shipments = []
      if response_success?(response)
        shipments = parse_shipments_response(body)
      end

      begin
        return ActiveMarket::Response.new(ActiveMarket::ShipmentsResult.new({shipments: shipments}), {body: body, code: response.code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    private
    def response_success?(response)
      return SUCCESS_CODES.include?(response.code)
    end

    def parse_shipments_response(body)
      shipments = []
      body["fulfillments"].each do |i|
        shipments << {
          id: i["fulfillmentId"],
          date: Time.parse(i["shippedDate"]),
          tracking_number: i["shipmentTrackingNumber"],
          carrier: i["shippingCarrierCode"],
          service_code: i["shippingServiceCode"]
        }
      end
      return shipments
    end

    def parse_orders_response(response)
      orders = []

      response["orders"].each do |o|
        order = ActiveMarket::Order.new(marketplace: "Ebay")

        if !["PAID", "FULLY_REFUNDED", "PARTIALLY_REFUNDED"].include? o["orderPaymentStatus"]
          #go to the next iteration because we don't want unpurchased orders!!
          next
        end

        if o["paymentSummary"]["payments"].any?
          order.payment_method = o["paymentSummary"]["payments"].first["paymentMethod"]
          order.transaction_id = o["paymentSummary"]["payments"].first["paymentReferenceId"]
        end

        order.payment_status = o["orderPaymentStatus"]
        order.order_number = o["orderId"]
        order.created_at = Time.parse(o["creationDate"])
        order.ordered_at = Time.parse(o["creationDate"])


        order.cancelled = o["cancelStatus"]["cancelState"] == "CANCELLED"
        if order.cancelled
          order.status = "Cancelled"
          order.cancelled_date = Time.parse(o["cancelStatus"]["cancelledDate"])
        else
          order.status = o["orderFulfillmentStatus"] == "FULFILLED" ? "Complete" : "Processing"
        end

        items_total = BigDecimal(0)
        product_discount = BigDecimal(0)
        #items
        o["lineItems"].each_with_index do |i, index|
          discount_amount = BigDecimal(0)
          i["appliedPromotions"].each do |x|
            discount_amount = (discount_amount + BigDecimal(x["discountAmount"]["value"].to_s)).round(2)
          end
          product_discount = (product_discount + discount_amount).round(2)
          order.items << {
            line_number: index,
            id: i["lineItemId"],
            name: i["title"],
            sku: i["sku"],
            price: (BigDecimal(i["lineItemCost"]["value"]) / BigDecimal(i["quantity"])).round(2),
            quantity: i["quantity"],
            discount_amount: discount_amount
          }

          items_total = (items_total + BigDecimal(i["lineItemCost"]["value"])).round(2)
        end
        order.product_discount = product_discount

        #address details
        shipping_info = o["fulfillmentStartInstructions"]
        shipping_info.each do |s|
          if s.has_key?("shippingStep")
            shipping_step = s["shippingStep"]
            details = shipping_step["shipTo"]
            name = details["fullName"].split(" ", 2)
            contactAddress = details["contactAddress"]

            order.shipping_method = shipping_step["shippingServiceCode"]
            order.addresses << {
              type: "Shipping",
              first_name: name.first,
              last_name: name.last,
              email: details["email"],
              telephone: (details["primaryPhone"]["phoneNumber"] if details.has_key?("primaryPhone")),
              address1: contactAddress["addressLine1"],
              address2: contactAddress["addressLine2"],
              city: contactAddress["city"],
              country: contactAddress["countryCode"],
              state: contactAddress["stateOrProvince"],
              postal_code: contactAddress["postalCode"]
            }
            break #found shipping address info can now break
          end
        end

        #get all shipments for an order
        #response = get_shipments(order.order_number)

        if o["pricingSummary"].has_key?("deliveryDiscount")
            order.shipping_discount = BigDecimal(o["pricingSummary"]["deliveryDiscount"]["value"].to_s)
        end

        #order.shipments = response.shipments

        order.shipping = o["pricingSummary"]["deliveryCost"]["value"]

        #calculate subtotal
        order.subtotal = (items_total + BigDecimal(order.shipping)).round(2)
        order.subtotal = (order.subtotal - order.product_discount).round(2)
        order.subtotal = (order.subtotal - order.shipping_discount).round(2)

        if o["pricingSummary"].has_key?("tax")
          order.tax = BigDecimal(o["pricingSummary"]["tax"]["value"].to_s)
        end
        order.grand_total = o["pricingSummary"]["total"]["value"]

        orders << order

      end#end response["list"]["elements"]["order"]

      return orders

    end
  end
end
