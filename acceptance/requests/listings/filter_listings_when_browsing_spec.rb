require './acceptance/spec_helper'

feature "Browse listings", %q{
  In order to quickly find items to buy
  As a user
  I want to narrow down the amount of listings
} do

  background do
    login_as "starbuck@galactica.mil"
    given_listings(
      { :title => "Marc Jacobs Rio Satchel", :category => "Handbags", :tag_string => "satchel" },
      { :title => "The Great Messenger Bag", :category => "Handbags", :tag_string => "messeger, bag" },
      { :title => "Tribal Leather Red Bag",  :category => "Handbags", :tag_string => "leather, bag" },
      { :title => "Black Leather Pants",     :category => "Clothing", :tag_string => "leather" }
    )
  end

  scenario "browse by tag" do
    visit browse_for_sale_path(:category => "handbags")
    filter_by_tag "Bag"

    your_navigation.should have_content("Bag")
    tag_filters.should have_no_content("Bag")
    page.should have(2).product_cards
  end

  scenario "browse by several tags" do
    visit browse_for_sale_path(:category => "handbags")
    filter_by_tag "Bag"
    filter_by_tag "Leather"

    your_navigation.should have_content("Leather")
    page.should have(1).product_card
  end

  scenario "remove tag filter" do
    visit browse_for_sale_path(:category => "handbags")
    filter_by_tag "Bag"
    filter_by_tag "Leather"
    remove_filter "Bag"

    your_navigation.should have_content("Leather")
    your_navigation.should have_no_content("Bag")
    page.should have(1).product_cards
  end

  scenario "browse by category" do
    visit browse_for_sale_path(:category => "handbags")

    your_navigation.should have_content("Handbags")
    page.should have(3).product_cards
  end

  scenario "remove category filter" do
    visit browse_for_sale_path(:category => "handbags")
    remove_filter("Handbags")

    your_navigation.should have_no_content("Handbags")
    page.should have(4).product_cards
  end

  scenario "removing category filter doesn't remove tag" do
    visit browse_for_sale_path(:category => "handbags")
    filter_by_tag "Bag"
    remove_filter("Handbags")

    page.should have(2).product_cards
    your_navigation.should have_no_content("Handbags")
  end
end
