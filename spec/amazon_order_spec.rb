require_relative "./spec_helper"
require 'active_market'
require "json"

describe ActiveMarket::Amazon do

  context 'orders' do
    it 'gets ama orders' do
      creds = ActiveMarket::Credential.new({
          client_id: "",
          client_secret: ""
      })
      o = ActiveMarket::Amazon::Order.new(creds, {marketplace: "", merchant_id: ""})
      response = o.get_orders({start_date: 1.minute.ago.utc.strftime("%Y-%m-%dT%H:%M:%S.000Z") })
      response.orders.each do |i|
        puts i.items.to_json
      end
    end
  end
end
