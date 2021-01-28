module ActiveMarket
  class Walmart < Marketplace

    attr_reader :token

    SUCCESS_CODES = %w(200 201).freeze

    def initialize(creds)
        @creds = creds
        @token = get_access_token.token
    end



    private
    def response_success?(response)
      return SUCCESS_CODES.include?(response.code)
    end

    def get_access_token
      uri = URI.parse("https://marketplace.walmartapis.com/v3/token")

      header = {
        'Authorization': "Basic #{Base64.encode64("#{@creds.client_id}:#{@creds.client_secret}").gsub("\n", '').chomp}",
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'WM_SVC.NAME': 'Walmart Marketplace',
        'WM_QOS.CORRELATION_ID': SecureRandom.uuid.to_s,
        'WM_SVC.VERSION': '1.0.0',
        'Host': 'marketplace.walmartapis.com'
      }

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = "grant_type=client_credentials"

      # Send the request
      response = http.request(request)

      begin
        return ActiveMarket::Response.new(ActiveMarket::TokenResult.new({token: JSON.parse(response.body)["access_token"]}), {body: JSON.parse(response.body), code: response.code})
      rescue ActiveMarket::ResponseError => e
        return ErrorHandler.new(e)
      end
    end
  end
end
