class ActiveMarket::Amazon
  #this class docorates result classes such as OrdersResult
  class ErrorHandler < ActiveMarket::ErrorHandler

    def initialize(response_error)
      super
    end

    private
    def process_error_codes

      if @response_error.secondary_type == Peddler::Errors::RequestThrottled
        raise ActiveMarket::TooManyRequestsError.new(@response_error.message)
      else
        raise @response_error
      end

    end

  end

  #error classes listed below here
  class AmazonError < ActiveMarket::ResponseError
  end
end
