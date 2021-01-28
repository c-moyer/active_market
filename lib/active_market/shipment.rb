module ActiveMarket
  class Shipment
    
    attr_accessor :order_number
    attr_accessor :created_at
    attr_accessor :carrier
    attr_accessor :service_used
    attr_accessor :tracking_number
    attr_accessor :items


    def initialize(opts = {})
      @items = []
    end
  end
end
