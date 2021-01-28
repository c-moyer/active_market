module ActiveMarket
  class OrdersResult
    attr_reader :orders
    attr_reader :next_page
    attr_reader :end_date
    def initialize(opts = {})
      @orders = opts[:orders] || []
      @next_page = opts[:next_page]
      @end_date = opts[:end_date]
    end
  end
end
