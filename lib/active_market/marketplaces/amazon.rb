module ActiveMarket
  class Amazon < Marketplace

    def initialize(creds, opts={})
      @marketplace = opts[:marketplace]
      @merchant_id = opts[:merchant_id]
      @creds = creds
    end




  end
end
