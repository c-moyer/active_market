require_relative "./spec_helper"
require 'active_market'
require "json"

describe ActiveMarket::Walmart do

  context 'orders' do
    it 'gets walmart orders' do

      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: ""
      })
      o = ActiveMarket::Walmart::Order.new(creds)
    #  begin
      response = o.get_orders({start_date: "2020-05-10T14:03:00Z", end_date: "2020-07-20T014:05:00Z", type: "released"})
      response.orders.each do |i|
        puts i.order_number
        i.items.each do |x|
          puts x.to_json
        end
        puts "--------------------------------"
      end
      puts "okok"
    #rescue => e
    #  puts e
  #  end

    end

    it 'gets a walmart order' do
      #16-05145-23548
      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: ""
      })
      o = ActiveMarket::Walmart::Order.new(creds)
    #  begin
      response = o.get_order("")
      puts response.order.order_number
    end

    it 'acks an order' do
      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: ""
      })
      o = ActiveMarket::Walmart::Order.new(creds)
      response = o.acknowledge("")
    end

    it 'creates shipment' do
      shipment = ActiveMarket::Shipment.new

      shipment.order_number = ""
      shipment.created_at = Time.now
      shipment.carrier = "USPS"
      shipment.service_used = "Express"
      shipment.tracking_number = ""


      shipment.items << ActiveMarket::Item.new({
          line_number: 1,
          quantity: 2
      })

      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: ""
      })
      o = ActiveMarket::Walmart::Order.new(creds)

      response = o.create_shipment(shipment)

    end

  end
end
