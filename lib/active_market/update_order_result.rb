module ActiveMarket
  class UpdateOrderResult
    attr_reader :order

    def initialize(opts = {})
      @order = opts[:order]
    end
  end
end
