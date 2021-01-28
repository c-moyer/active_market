module ActiveMarket
  #decorates a result set with response details
  class Response < SimpleDelegator

    attr_reader :body
    attr_reader :code
    attr_reader :message


    HTTP_ERR_CODES = %w(500 404 400 520)

    def initialize(result, opts = {})
      @result = result
      @body = opts[:body]
      @code = opts[:code]
      success = !HTTP_ERR_CODES.include?(code)

      super(result)

      raise ResponseError.new("Server response code: #{code}", {body: body, code: code}) unless success

      @message = "Success"
    end

    def success?
      return @success
    end



  end
end
