class ActiveMarket::Walmart

  class Order < ActiveMarket::Walmart


    def initialize(creds)
      super(creds)
      @header = {
        'Authorization': "Basic #{Base64.encode64("#{@creds.client_id}:#{@creds.client_secret}").gsub("\n", '').chomp}",
        'Accept': 'application/json',
        'WM_SVC.NAME': 'Walmart Marketplace',
        'WM_SEC.ACCESS_TOKEN': @token,
        'Host': 'marketplace.walmartapis.com'
      }
    end

    def acknowledge(order_number)

      uri = URI.parse("https://marketplace.walmartapis.com/v3/orders/#{order_number}/acknowledge")
      header = @header
      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s
      header["Content-Type"] = 'application/x-www-form-urlencoded'

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)

      # Send the request
      response = http.request(request)
      code = response.code
      if valid_json?(response.body)
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      begin
        #UpdateOrderResult will take an order and a parse method needs to be implemented
        return ActiveMarket::Response.new(ActiveMarket::UpdateOrderResult.new, {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    def create_shipment(shipment)

      line_items = []
      shipment.items.each do |i|
        line_items << {
          lineNumber: i.line_number,
          orderLineStatuses: {
            orderLineStatus: [
              status: "Shipped",
              statusQuantity: {
              unitOfMeasurement: "EACH",
                amount: i.quantity
              },
              trackingInfo: {
                shipDateTime: shipment.created_at.strftime('%s%L'),
                carrierName: {
                  otherCarrier: nil,
                  carrier: shipment.carrier
                },
                methodCode: shipment.service_used,
                trackingNumber: shipment.tracking_number
              }
            ]
          }
        }
      end

      shipping = {
        orderShipment: {
          orderLines:{
            orderLine: line_items
          }
        }
      }

      uri = URI.parse("https://marketplace.walmartapis.com/v3/orders/#{shipment.order_number}/shipping")

      header = @header
      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s
      header["Content-Type"] = 'application/x-www-form-urlencoded'


      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = shipping.to_json

      # Send the request
      response = http.request(request)

      body = JSON.parse(response.body)
      code = response.code

      begin
        return ActiveMarket::Response.new(ActiveMarket::CreateShipmentResult.new(), {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    def get_order(order_number)
      endpoint = "https://marketplace.walmartapis.com/v3/orders/#{order_number}"
      uri = URI.parse(endpoint)

      header = @header

      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, header)

      # Send the request
      response = http.request(request)

      success = response_success?(response)
      code = response.code

      if valid_json?(response.body)
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      if success
        order = parse_order_response(body["order"])
      end


      begin
        return ActiveMarket::Response.new(ActiveMarket::OrderResult.new({order: order}), {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    def get_orders(opts = {})
      if opts[:type] == "released"
        endpoint = "https://marketplace.walmartapis.com/v3/orders/released#{opts[:next_page]}"
      else
        raise "not yet supported"
        #endpoint = "https://marketplace.walmartapis.com/v3/orders#{opts[:next_page]}"
      end

      uri = URI.parse(endpoint)

      header = @header

      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s

      if opts[:next_page] == nil && opts[:start_date] != nil && opts[:end_date] != nil

        #only send params if next page is nil. Sending blank params hash will cause errors.
        params = {
          #gets orders before and after the start and end dates format: 2020-01-16T10:30:15Z
          'createdStartDate' => (Time.parse(opts[:start_date]) - 1.second).strftime("%Y-%m-%dT%H:%M:%SZ"),
          'createdEndDate' => (Time.parse(opts[:end_date]) + 1.second).strftime("%Y-%m-%dT%H:%M:%SZ"),
          'limit' => 200
        }

        uri.query = URI.encode_www_form(params)
      end

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, header)

      # Send the request
      response = http.request(request)

      success = response_success?(response)
      code = response.code

      if valid_json?(response.body)
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      if success
        orders = parse_orders_response(body)
      end

      begin
        return ActiveMarket::Response.new(ActiveMarket::OrdersResult.new({orders: orders, next_page: (body["list"]["meta"]["nextCursor"] unless !success) }), {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end

    end#end get_orders

    def get_next_page(next_page: nil)
      raise ArgumentError "next_page should not be nil" if next_page.nil?
      endpoint = "https://marketplace.walmartapis.com/v3/orders#{next_page}"
      uri = URI.parse(endpoint)
      
      header = @header

      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, header)

      # Send the request
      response = http.request(request)

      success = response_success?(response)
      code = response.code

      if valid_json?(response.body)
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      if success
        orders = parse_orders_response(body)
      end

      begin
        return ActiveMarket::Response.new(ActiveMarket::OrdersResult.new({orders: orders, next_page: (body["list"]["meta"]["nextCursor"] unless !success) }), {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end

    def get_all_since(time_ago: 24.hours)

      def time_to_api_time(time)
        time.strftime("%Y-%m-%dT%H:%M:%SZ")
      end

      end_time = Time.current
      start_time = end_time - time_ago

      endpoint = "https://marketplace.walmartapis.com/v3/orders"
      uri = URI.parse(endpoint)
      params = {
        #gets orders before and after the start and end dates format: 2020-01-16T10:30:15Z
        'createdStartDate' => time_to_api_time(start_time),
        'createdEndDate' => time_to_api_time(end_time),
        'limit' => 200
      }
      uri.query = URI.encode_www_form(params)


      header = @header

      header["WM_QOS.CORRELATION_ID"] = SecureRandom.uuid.to_s

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri, header)

      # Send the request
      response = http.request(request)

      success = response_success?(response)
      code = response.code

      if valid_json?(response.body)
        body = JSON.parse(response.body)
      else
        body = response.body
      end

      if success
        orders = parse_orders_response(body)
      end

      begin
        return ActiveMarket::Response.new(ActiveMarket::OrdersResult.new({orders: orders, next_page: (body["list"]["meta"]["nextCursor"] unless !success) }), {body: body, code: code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end


    end


    private
    def parse_orders_response(response)
      orders = []
      #puts JSON.pretty_generate(response)

      response["list"]["elements"]["order"].each do |i|
        orders << parse_order_response(i)
      end#end response["list"]["elements"]["order"]

      return orders

    end

    def parse_order_response(response)
      order = ActiveMarket::Order.new(marketplace: "walmart.com")
      order.status = "Processing"
      order.order_number = response["purchaseOrderId"]
      order.ordered_at = Time.at(response["orderDate"].to_f/1000)
      order.payment_method = "Walmart Payment"

      #address details
      shipping_info = response["shippingInfo"]
      address = shipping_info["postalAddress"]
      name = address["name"].split(" ", 2)
      order.addresses << {
        type: "Shipping",
        first_name: name.first,
        last_name: name.last,
        email: response["customerEmailId"],
        telephone: shipping_info["phone"],
        address1: address["address1"],
        address2: address["address2"],
        city: address["city"],
        country: address["country"],
        state: address["state"],
        postal_code: address["postalCode"]
      }

      order.shipping_method = shipping_info["methodCode"]

      subtotal = BigDecimal("0")
      tax = BigDecimal("0")
      grand_total = BigDecimal("0")
      shipping = BigDecimal("0")

      #line items
      line_items = response["orderLines"]["orderLine"]
      line_items.each do |x|

        item_price = BigDecimal("0")
        charges = x["charges"]["charge"]

        charges.each do |z|

          if z["chargeType"] == "PRODUCT"
            #tally product charges
            item_price = BigDecimal(z["chargeAmount"]["amount"].to_s)
            subtotal = (subtotal + item_price).round(2)
          else
            #tally shipping charges
            shipping_price = BigDecimal(z["chargeAmount"]["amount"].to_s)
            shipping = (shipping + shipping_price).round(2)
          end

          if z.has_key?("tax") && z["tax"] != nil && z["tax"].has_key?("taxAmount")
            tax_amount = BigDecimal(z["tax"]["taxAmount"]["amount"].to_s)
            tax = (tax + tax_amount).round(2)
          end

        end#end charges

        order.items << {
          id: x["lineNumber"],
          line_number: x["lineNumber"],
          name: x["item"]["productName"],
          sku: x["item"]["sku"],
          price: item_price,
          quantity: x["orderLineQuantity"]["amount"]
        }

      end#end line_items

      order.subtotal = (subtotal + shipping).round(2)
      order.shipping = shipping
      order.tax = tax
      order.grand_total = (tax + order.subtotal).round(2)

      return order
    end

  end

end
