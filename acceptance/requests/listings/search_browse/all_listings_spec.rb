require './acceptance/spec_helper'
require 'timecop'

feature "Browse listings when logged in", %q{
  In order to find items to buy
  As a user
  I want to browse listings
} do

  background do
    login_as "starbuck@galactica.mil"
  end

  scenario "should show listings" do
    given_listing(title: "Marc Jacobs Rio Satchel", category: "Handbags")
    visit browse_for_sale_path(:category => "handbags")

    page.should have_content("Handbags")
    page.should have(1).product_card
  end

  context 'for a specific product card' do
    let!(:listing) { given_listing(title: "Marc Jacobs Rio Satchel", category: "Handbags") }

    scenario "I should be able to like and unlike it", js: true do
      visit browse_for_sale_path
      like_product_card(listing)
      product_card_should_be_liked(listing)
      unlike_product_card(listing)
      product_card_should_not_be_liked(listing)
    end
  end

  scenario "browse with no listings" do
    given_category "Action Figures"

    visit browse_for_sale_path(category: "action-figures")

    page.should have_content("Action Figures")
    page.should have(:no).product_cards
    page.should_not have_connect_buttons
  end

  scenario "browse only active listings" do
    given_listings(title: "Marc Jacobs Rio Satchel", category: "Handbags", state: "incomplete")

    visit browse_for_sale_path(:category => "handbags")

    page.should have_content("Handbags")
    page.should have(:no).product_cards
  end

  scenario 'facet selection', js: true do
    given_listings(
      { title: "Red T-Shirt", category: "Clothing", tags: ['Red', 'T-Shirt'], size: 'M', price: 22.00 },
      { title: "Blue T-Shirt", category: "Clothing", tags: ['Blue', 'T-Shirt'], size: 'L', price: 30.00 },
      { title: "Black T-Shirt", category: "Clothing", tags: ['Black', 'Vintage'], size: 'L', price: 260.00 }
    )
    visit browse_for_sale_path(category: 'clothing')

    expect(page).to have_content("Clothing")
    expect(page).to have(3).product_cards

    click_facet_and_validate('L')
    expect(page).to have(2).product_cards

    click_facet_and_validate('Vintage')
    expect(page).to have(1).product_card

    visit browse_for_sale_path(category: 'clothing')

    expect(page).to have_content("Clothing")
    expect(page).to have(3).product_cards

    click_facet_and_validate('Over $250')
    expect(page).to have(1).product_card

    click_facet_and_validate('Under $25')
    expect(page).to have(2).product_cards
  end

  scenario 'infinite scroll', js: true do
    listings_per_page = Brooklyn::Application.config.listings.browse.per_page
    total_listings = listings_per_page + 10
    given_listings(*(total_listings.times.map { |i| { title: "Marc Jacobs Rio Satchel #{i}", category: "Handbags" } }))
    visit browse_for_sale_path(:category => "handbags")

    page.should have_content("Handbags")
    page.should have(listings_per_page).product_cards
    scroll_window_to_bottom
    page.should have(total_listings).product_cards
  end

  scenario "should show featured listings for a category" do
    pending "featured listings have been temporarily removed"
    listing = given_listings({title: "Marc Jacobs Rio Satchel", category: "Handbags"},
                             {title: "Ham Toner", category: "Toners"}).first
    listing.category.feature(listing)
    visit browse_for_sale_path(:category => "handbags")
    within ".featured-products-wrap" do
      page.should have(1).featured_product_card
      page.should have_content('Marc Jacobs Rio Satchel')
      page.should have_selector '.prev'
      page.should have_selector '.next'
      page.should have_selector '.navi'
    end
  end

  scenario "should show featured listings for a tag" do
    pending "featured listings have been temporarily removed"
    listing = given_listings({title: "Marc Jacobs Rio Satchel", category: "Handbags", tags: ['hams']},
                             {title: "Ham Toner", category: "Toners"}).first
    listing.tags.first.feature(listing)
    visit browse_for_sale_path(:path_tags => "hams")
    within ".featured-products-wrap" do
      page.should have(1).featured_product_card
      page.should have_content('Marc Jacobs Rio Satchel')
    end
  end

  context "social actions" do
    let(:rfb) { given_registered_user name: 'Smokey' }
    let(:friend) { given_registered_user name: 'The Bandit' }

    scenario "should show actions people I am following have taken" do
      pending('XXXrisingtide: depend once we figure out story creation in acceptance')
      given_a_listing_with_likes_from_friends_and_others
      visit browse_for_sale_path
      page.should have_content("#{friend.name} liked this")
    end

    def given_a_listing_with_likes_from_friends_and_others
      given_organic_follow(friend, current_user)
      listing = given_listing(title: "Marc Jacobs Rio Satchel", category: "Handbags")
      given_like(listing, friend)
      Timecop.travel(Time.now + 5)
      given_like(listing, rfb)
    end
  end

  def click_facet_and_validate(label)
    find("[data-title='#{label}']").click
    wait_a_while_for do
      expect(page).to have_xpath("//span[@data-role='facet-selection' and starts-with(.,'#{label}')]")
    end
  end
end

feature "Browse listings when not logged in" do
  background do
    @listing = given_listing
  end

  scenario "should show listings" do
    given_listing
    visit browse_for_sale_path(category: @listing.category.slug)
    page.should have_content(@listing.category.name)
    page.should have(1).product_card
    page.should have_connect_buttons
  end
end

