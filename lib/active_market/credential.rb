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

    def self.load_from_environment(api_target: nil)
      raise ArgumentError.new "api_target is expected, was #{api_target}" if api_target.nil?
      case api_target
      when :walmart
        creds = {
          client_id: ENV["walmart_client_id"],
          client_secret: ENV["walmart_client_secret"]
        }
      else
        raise StandardError.new "could not set creds for api_target #{api_target}"
      end
      raise StandardError.new "some cred failed to load #{creds}" if creds.values.any?(&:nil?)
      self.new(creds)
    end

  end
end 
