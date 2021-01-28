module ActiveMarket
  class Order
    attr_accessor :status
    attr_accessor :shipping_method
    attr_accessor :addresses
    attr_accessor :created_at
    attr_accessor :ordered_at
    attr_accessor :order_number
    attr_accessor :items
    attr_accessor :tax
    attr_accessor :shipping
    attr_accessor :subtotal
    attr_accessor :grand_total
    attr_accessor :payment_status
    attr_accessor :cancelled
    attr_accessor :cancelled_date
    attr_accessor :shipments
    attr_accessor :amazon_prime
    attr_accessor :marketplace
    attr_accessor :fulfillment_channel
    attr_accessor :shipping_discount
    attr_accessor :product_discount
    attr_accessor :payment_method
    attr_accessor :transaction_id
    attr_accessor :fulfillment_channel
    attr_accessor :amazon_prime

    def initialize(opts = {})
      @marketplace = opts[:marketplace]
      @items = []
      @addresses = []
      @shipments = []
      @shipping_discount = BigDecimal(0)
      @product_discount = BigDecimal(0)
      @subtotal = BigDecimal(0)
      @tax = BigDecimal(0)
      @shipping = BigDecimal(0)
      @grand_total = BigDecimal(0)
    end
  end
end
