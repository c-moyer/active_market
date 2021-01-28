class ActiveMarket::Ebay
  #this class docorates result classes such as OrdersResult
  class ErrorHandler < ActiveMarket::ErrorHandler

    def initialize(response_error)
      super
    end

    private
    def process_error_codes
      errors = []
      #return errors unless valid_json?(@response_error.body) && @response_error.body.has_key?("errors")

      @response_error.body["errors"].each do |i|

        case i["errorId"]
        when "2001"
          raise TooManyRequestsError(i["message"])
        else
          errors << "#{i["errorId"]} - #{i["message"]}"
        end

      end
      puts @response_error.body
      raise @response_error
    end
  end

  #error classes listed below here
  class EbayError < ActiveMarket::ResponseError
  end
end
