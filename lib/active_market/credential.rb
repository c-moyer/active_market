module ActiveMarket


  class Credential

    attr_reader :client_id
    attr_reader :client_secret
    attr_reader :auth_code
    attr_reader :refresh_token

    def initialize(credentials)
      @client_id = credentials[:client_id]
      @client_secret = credentials[:client_secret]
      @refresh_token = credentials[:refresh_token]
      @auth_code = credentials[:auth_code]
    end

  end

end
