module ActiveMarket
  class ShipmentsResult
    attr_reader :shipments
    def initialize(opts = {})
      @shipments = opts[:shipments] || []
    end
  end
end
