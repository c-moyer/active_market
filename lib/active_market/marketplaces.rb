module ActiveMarket
  module Marketplaces
    extend self

    attr_reader :registered
    @registered = []

    def register(class_name, autoload_require)
      ActiveMarket.autoload(class_name, autoload_require)
      self.registered << class_name
    end

  end
end

ActiveMarket::Marketplaces.register :Walmart,            'active_market/marketplaces/walmart'
ActiveMarket::Marketplaces.register :Ebay,            'active_market/marketplaces/ebay'
ActiveMarket::Marketplaces.register :Amazon,            'active_market/marketplaces/amazon'
