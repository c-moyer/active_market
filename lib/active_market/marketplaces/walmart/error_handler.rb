class ActiveMarket::Walmart
  #this class docorates result classes such as OrdersResult
  class ErrorHandler < ActiveMarket::ErrorHandler

    def initialize(response_error)
      super
    end

    private
    def process_error_codes
      errors = []


      if @response_error.code.to_s == "429"
        raise TooManyRequestsError("Your request has been throttled")
      end

      if @response_error.body.is_a?(Hash)
      #return errors unless valid_json?(@response_error.body) && @response_error.body.has_key?("errors")
        @response_error.body["errors"]["error"].each do |i|
          @response_error.messages << i["code"]
        end

      end

      raise @response_error
    end
  end

  #error classes listed below here
  class WalmartError < ActiveMarket::ResponseError
  end
end
