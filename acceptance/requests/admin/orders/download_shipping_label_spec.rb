require './acceptance/spec_helper'

feature 'Download shipping label as admin' do
  let!(:order) { given_order(:confirmed) }
  let!(:shipping_option) { FactoryGirl.create(:shipping_option, listing: order.listing) }
  let!(:shipping_label) { FactoryGirl.create(:shipping_label, order: order) }

  include_context 'selling a listing with prepaid shipping'

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "download label" do
    set_up_label_file
    visit admin_order_path(order)
    download_label
    label_file_should_be_downloaded
  end
end
