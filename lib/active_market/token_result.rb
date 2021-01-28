module ActiveMarket
  class TokenResult
    attr_reader :token
    def initialize(opts = {})
      @token = opts[:token]
    end
  end
end
