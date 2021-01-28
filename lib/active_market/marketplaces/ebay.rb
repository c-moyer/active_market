module ActiveMarket
  class Ebay < Marketplace

    TEST_URL = "https://api.sandbox.ebay.com/identity/v1/oauth2/token"
    PRODUCTION_URL = "https://api.ebay.com/identity/v1/oauth2/token"

    attr_reader :token

    def initialize(creds)
        #consent_url
        @domain = "https://api.ebay.com"
        @creds = creds
        @header = {
          #Docs say to use this header but including it causes a 500 server error. 'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': "Basic #{Base64.encode64("#{@creds.client_id}:#{@creds.client_secret}").gsub("\n", '').chomp}"
        }
        @token = refresh_token.token


    end

    def consent_url
      endpoint = "https://auth.ebay.com/oauth2/authorize"
      uri = URI.parse(endpoint)
      params = {
        'client_id': @creds.client_id,
        'redirect_uri': 'https://www.treadmilldoctor.com/admin/ebay/config',
        'response_type': 'code',
        'scope': 'https://api.ebay.com/oauth/api_scope/sell.fulfillment',
        'prompt': 'login'
      }
      uri.query = URI.encode_www_form(params)
      return uri
    end

    def refresh_token
      uri = URI.parse(@domain + "/identity/v1/oauth2/token")

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      params = {
        grant_type: "refresh_token",
        refresh_token: @creds.refresh_token,
        scope: 'https://api.ebay.com/oauth/api_scope/sell.fulfillment',
      }
      uri.query = URI.encode_www_form(params)
      request = Net::HTTP::Post.new(uri.request_uri, @header)

      # Send the request
      response = http.request(request)

      begin

        return ActiveMarket::Response.new(ActiveMarket::TokenResult.new({token: JSON.parse(response.body)["access_token"]}), {body: JSON.parse(response.body), code: response.code})

      rescue ActiveMarket::ResponseError => e

        return ErrorHandler.new(e)

      end

    end

    def get_user_tokens
      #this is only used if something just goes wrong, will fully implement later
      uri = URI.parse(@domain + "/identity/v1/oauth2/token")

      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      params = {
        grant_type: "authorization_code",
        code: CGI.unescape(@creds.auth_code),
        redirect_uri: "https://www.treadmilldoctor.com/admin/ebay/config"
      }
      #uri.query = URI.encode_www_form(params)
      request = Net::HTTP::Post.new(uri.request_uri, @header)
      #query = URI.encode_www_form(params)
      request.body = URI.encode_www_form(params)
      # Send the request
      response = http.request(request)
      puts response.body
      return JSON.parse(response.body)
    end
  end#end class ebay

end
