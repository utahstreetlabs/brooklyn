require './acceptance/spec_helper'

feature "Edit internal listings", %q{
  In order to sell an item that was published with an error
  As a registered user
  I want to update the item's details
} do

  let! :handbags do
    given_category "Handbags"
  end

  background do
    given_registered_user email: "starbuck@galactica.mil"

    given_dimension "Condition", category: handbags, values: [
      "New with tags", "New without tags", "Used - excellent", "Used - fair"
    ]

    given_listings title: "Marc Jacobs Rio Satchel",
                   category: "Handbags",
                   condition: "Used - excellent",
                   price: 150.00,
                   shipping: 5.00,
                   size: "Medium",
                   seller: "starbuck@galactica.mil"

    login_as "starbuck@galactica.mil"
  end

  let :listing do
    Listing.find_by_title("Marc Jacobs Rio Satchel")
  end

  scenario "change title" do
    visit edit_listing_path(listing)

    fill_in "Listing title", with: "New title"
    click_button "preview_listing"

    expect(current_path).to eq(listing_path(listing))
    expect(flash_notice).to have_content("Your changes to the listing were saved.")
    expect(page).to have_content("New title")
  end

  scenario "change description" do
    visit edit_listing_path(listing)

    fill_in "Description", with: "Oh yeah!"
    click_button "preview_listing"

    current_path.should == listing_path(listing)
    flash_notice.should have_content("Your changes to the listing were saved.")
    page.should have_content("Oh yeah!")
  end

  scenario "change condition" do
    visit edit_listing_path(listing)

    select "Used - excellent", from: "Condition"
    click_button "preview_listing"

    current_path.should == listing_path(listing)
    flash_notice.should have_content("Your changes to the listing were saved.")
    page.should have_content("Used - excellent")
  end

  scenario 'change size', js: true do
    given_size_tag("Large")
    visit edit_listing_path(listing)

    set_size("Large")
    click_button "preview_listing"

    update_listing_should_succeed
    flash_notice.should have_content("Your changes to the listing were saved.")

    page.should_not have_size('Medium')
    page.should have_size('Large')
  end

  scenario 'remove size', js: true do
    visit edit_listing_path(listing)

    # ensure that combobox has finished modifying dom
    retry_expectations { page.should have_selector('i.icon-remove') }
    within('#field_size_name') { find('i.icon-remove').click }
    click_button "preview_listing"

    update_listing_should_succeed
    flash_notice.should have_content("Your changes to the listing were saved.")

    page.should_not have_any_size
  end

  scenario "change tags" do
    visit edit_listing_path(listing)

    fill_in "Tags", with: "black, leather, travel"
    click_button "preview_listing"

    update_listing_should_succeed
    flash_notice.should have_content("Your changes to the listing were saved.")

    page.should have_content("black")
    page.should have_content("leather")
    page.should have_content("travel")
  end

  scenario "change price" do
    visit edit_listing_path(listing)

    fill_in "listing_price", with: "149.99"
    click_button "preview_listing"

    current_path.should == listing_path(listing)
    flash_notice.should have_content("Your changes to the listing were saved.")
    page.should have_content("$149.99")
  end

  scenario "change to free basic shipping", js: true do
    visit edit_listing_path(listing)
    enter_shipping_amount 0.00
    choose_basic_shipping
    click_button "preview_listing"
    update_listing_should_succeed
    shipping.should == "$0.00"
  end

  scenario "change to non-free basic shipping", js: true do
    visit edit_listing_path(listing)
    retry_expectations {
      enter_shipping_amount 10.00
      choose_basic_shipping
      expect(page).to have_unchecked_field('listing_free_shipping')
    }
    click_button "preview_listing"
    update_listing_should_succeed
    shipping.should == "$10.00"
  end

  scenario "change to free prepaid shipping", js: true do
    visit edit_listing_path(listing)
    enter_shipping_amount 0.00
    choose_prepaid_shipping :medium_box
    click_button "preview_listing"
    update_listing_should_succeed
    shipping.should == "$0.00"
  end

  scenario "change to non-free prepaid shipping", js: true do
    visit edit_listing_path(listing)
    retry_expectations {
      enter_shipping_amount 10.00
      choose_prepaid_shipping :medium_box
      expect(find('#listing_free_shipping').checked?).to be_false
    }
    click_button "preview_listing"
    update_listing_should_succeed
    shipping.should == "$10.00"
  end

  def update_listing_should_succeed
    retry_expectations { current_path.should == listing_path(listing) }
  end
end
