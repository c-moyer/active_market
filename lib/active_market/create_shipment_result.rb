module ActiveMarket
  class CreateShipmentResult
    attr_reader :order

    def initialize(opts = {})
      @order = opts[:order]
    end
  end
end
