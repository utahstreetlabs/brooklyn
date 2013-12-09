require 'spec_helper'

describe Orders::AfterCompletionJob do
  subject { Orders::AfterCompletionJob }

  let(:buyer) { stub_user 'buyer', completed_bought_orders_count: 1 }
  let(:seller) { stub_user 'seller', completed_sold_orders_count: 1 }
  let(:listing) { stub_listing 'hot pockets', seller: seller }
  let(:order) { stub_order listing, buyer: buyer }

  describe '#update_mixpanel' do
    it 'should mark the buyer as a buyer and the seller as a seller' do
      buyer.expects(:mark_buyer!)
      buyer.expects(:mixpanel_sync!)
      buyer.expects(:mixpanel_increment!).
        with(purchases: 1, purchase_dollars: listing.subtotal, credits_used: order.credit_amount)
      seller.expects(:mark_seller!)
      seller.expects(:mixpanel_sync!)
      seller.expects(:mixpanel_increment!).with(sales: 1, sales_dollars: listing.subtotal)
      subject.update_mixpanel(order)
    end
  end
end
