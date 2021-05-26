require_relative "./spec_helper"
require 'active_market'
require "json"

describe ActiveMarket::Ebay do

  context 'gets ebay orders' do

    it 'creates a shipment' do
      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: "",
          auth_code: "",
          refresh_token: ""
      })
      o = ActiveMarket::Ebay::Order.new(creds)
      shipment = ActiveMarket::Shipment.new
      shipment.order_number = ""
      shipment.created_at = Time.now
      shipment.tracking_number = ""
      shipment.carrier = "USPS"
      shipment.items << ActiveMarket::Item.new({id: ""})

      response = o.create_shipment(shipment)
      puts response.code
    end


    it 'get orders' do
      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: "",
          auth_code: "",
          refresh_token: ""
      })
      o = ActiveMarket::Ebay::Order.new(creds)
      response = o.get_orders({start_date: "2020-05-20T01:05:00.000Z", end_date: "2020-05-22T014:05:00.000Z" })

      response.orders.each do |i|
        i.items.each do |x|


        end
      end
    end
  end
end
