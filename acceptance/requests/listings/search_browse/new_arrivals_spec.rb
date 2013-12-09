require './acceptance/spec_helper'

feature "Browse new arrivals" do
  scenario "shows an approved listing created recently" do
    given_listing(approved: true, approved_at: 5.minutes.ago)
    visit new_arrivals_for_sale_path
    page.should have(1).product_card
  end

  scenario "does not show an approved listing created a while ago" do
    given_listing(approved: true, approved_at: (Listing.browse_new_arrivals_since + 5.days).ago)
    visit new_arrivals_for_sale_path
    page.should have(0).product_cards
  end

  scenario "does not show a yet to be approved listing" do
    given_listing(approved: nil, approved_at: nil)
    visit new_arrivals_for_sale_path
    page.should have(0).product_cards
  end

  scenario "does not show a disapproved listing" do
    given_listing(approved: false, approved_at: 5.minutes.ago)
    visit new_arrivals_for_sale_path
    page.should have(0).product_cards
  end
end
