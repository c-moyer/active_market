module ActiveMarket
  class ErrorHandler
    def initialize(response_error)
      @response_error = response_error
      if @response_error.class != ActiveMarket::ResponseError
        raise NotImplementedError("Must pass ActiveMarket::ResponeError to constructor.")
      end

      @response_error.messages = process_error_codes
      raise
    end

    def process_error_codes
      raise NotImplementedError
    end

    def valid_json?(json)
        JSON.parse(json)
        return true
      rescue JSON::ParserError => e
        return false
    end
  end
end
