require './acceptance/spec_helper'

feature "Reserved purchase timer" do
  let!(:listing) { given_listing(price: 100, shipping: 0, seller_pays_marketplace_fee: true) }
  include_context 'purchasing a listing'

  scenario "cancel the order while timer is active", js: true do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    click_cancel_order
    wait_a_sec_for_selenium
    should_be_on_listing_page(listing)
    page.should have_content("Your order was canceled")
  end

  scenario "cancels the order after timer expires", js: true do
    visit listing_path(listing)
    begin_purchase
    should_be_on_shipping_page(listing)
    trigger_expire_order
    should_be_on_listing_page(listing)
    page.should have_content("Your reserved time has expired")
  end

  def trigger_expire_order
    # setting until to +0 tells the countdown timer to expire now.
    page.execute_script("$(\"[data-role='reserved-time-ticker']\").countdown('change',{until: +0})");
    wait_a_sec_for_selenium
  end

  def click_cancel_order
    page.find(:css, "[data-role='reserved-time-cancel']").click()
  end
end
