require "spec_helper"

describe "api/orders/index.xml.builder" do

  let(:address) do
    stub('address', line1: '123 Test Street', line2: 'apt. 1', city: 'San Francisco', state: 'CA', zip: '94103',
        phone: '208-231-1234')
  end
  let(:listing) do
    stub('listing',  title: 'listing title', slug: 'listing-title-1', price: 33, source_uid: '123456',
      description: 'this is a description', shipping: 5, category: 'clothing', proceeds: 10, sold?: true,
      buyer: stub(name: 'Buyer Name', email: 'buyer@example.com', uuid: 'a44c7549-149b-49b0-b68f-c1243500f30c'))
  end
  let(:order) do
    stub('order', reference_number: '3LKCEQZ9FFXRL3K', status: 'confirmed', created_at: '2011-10-08 00:58:59',
      shipping_address: address, listing: listing, payment_type: 'Balanced')
  end
  let(:orders) { [order] }

  before do
    assign(:orders, orders)
  end

  context "listings" do
    subject { rendered }
    before do
      render template: "/api/orders/index.xml.builder" 
    end

    it { should have_xpath("//orders", count: 1) }
    it { should have_xpath("//orders/order", count: 1) }
    it { should have_xpath("//orders/order/reference", text: '3LKCEQZ9FFXRL3K') }
    it { should have_xpath("//orders/order/status", text: 'confirmed') }
    it { should have_xpath("//orders/order/listing/slug", text: 'listing-title-1') }
    it { should have_xpath("//orders/order/listing/source_uid", text: '123456') }
    it { should have_xpath("//orders/order/listing/link", count: 2) }
    it { should have_xpath("//orders/order/buyer/name", text: 'Buyer Name') }
    it { should have_xpath("//orders/order/buyer/email", text: 'buyer@example.com') }
    it { should have_xpath("//orders/order/buyer/uuid", text: 'a44c7549-149b-49b0-b68f-c1243500f30c') }
    it { should have_xpath("//orders/order/buyer/line1", text: '123 Test Street') }
    it { should have_xpath("//orders/order/buyer/line2", text: 'apt. 1') }
    it { should have_xpath("//orders/order/buyer/city", text: 'San Francisco') }
    it { should have_xpath("//orders/order/buyer/state", text: 'CA') }
    it { should have_xpath("//orders/order/buyer/zip", text: '94103') }
    it { should have_xpath("//orders/order/buyer/phone", text: '208-231-1234') }
    it { should have_xpath("//orders/order/discount", text: '0.0') }
    it { should have_xpath("//orders/order/proceeds", text: '10') }
    it { should have_xpath("//orders/order/payment_type", text: 'Balanced') }
    it { should have_xpath("//orders/order/order_time", text: '1318035539') }
  end
end
