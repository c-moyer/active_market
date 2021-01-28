module ActiveMarket
  class Item
    attr_accessor :id
    attr_accessor :line_number
    attr_accessor :quantity

    def initialize(opts = {})
      @id = opts[:id]
      @line_number = opts[:line_number]
      @quantity = opts[:quantity]
    end
  end
end
