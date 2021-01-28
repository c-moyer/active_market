module ActiveMarket
  class Error < StandardError; end
  # Your code goes here...

  #generic response error
  class ResponseError < Error
    attr_reader :message
    attr_reader :body
    attr_reader :code
    attr_accessor :messages
    attr_reader :secondary_type
    def initialize(message, opts = {})
      @message = message
      @messages = opts[:messages] || []
      @body = opts[:body]
      @code = opts[:code]
      @secondary_type = opts[:secondary_type]
      @success = false
    end
  end

  class TooManyRequestsError < ResponseError
    attr_reader :message
    def initialize(message)
      @message = message
    end
  end

end
