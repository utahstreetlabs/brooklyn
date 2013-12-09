require './acceptance/spec_helper'
require 'timecop'

feature "LIH feed" do
  # XXX: turns out rspec executes all the work of included contexts before realizing these are pended.
  # so put them in their own context until we deal with that.
  # and comment out the background
  context "stories (all pending rising tide support in integration test)" do
    # include_context "curated user"
    # include_context "join stories"
    # include_context "users with follow relationships"
    # include_context "mock facebook profile"


    scenario "scrolling to bottom of feed should load more stories", js: true do
      pending('XXXrisingtide: depend once we figure out story creation in acceptance')
      visit_the_everything_feed
      within_listing_feed do
        page.should have(0).product_cards
        60.times { generate_new_listing_story }
      end

      refresh_listings_feed
      page.should have(product_cards_limit).product_cards
      scroll_window_to_bottom
      page.should have(57).product_cards
    end

    scenario "clicking scroll to top button should jump to top of feed", js: true do
      pending('XXXrisingtide: depend once we figure out story creation in acceptance')
      visit_the_everything_feed
      within_listing_feed do
        page.should have(0).product_cards
        33.times { generate_new_listing_story }
      end

      refresh_listings_feed
      page.should have(product_cards_limit).product_cards
      scroll_window_to_middle
      click_scroll_to_top_button
      page_should_be_at_top
    end

    context "given a listing activity exists" do
      let(:listing) { given_listing }
      # also commented out becase this test is not currently run
      # before { given_like(listing, followee) }

      scenario "new in my network widget should not display listing related activities" do
        pending('XXXrisingtide: depend once we figure out story creation in acceptance')
        visit_the_everything_feed
        within_new_in_network do
          page.should_not have_content("#{followee.name} liked #{listing.title}")
        end
      end
    end

    context "listing feed refresh" do
      scenario "new in my network widget should prompt user when there are new feed stories", js: true, flakey: true do
        pending('XXXrisingtide: depend once we figure out story creation in acceptance')
        visit_the_everything_feed
        within_listing_feed do
          page.should have(0).product_cards
        end
        generate_new_listing_story
        Timecop.travel(Time.now + 5)

        refresh_listings_feed(1)

        within_listing_feed do
          page.should have(1).product_card
        end
      end
    end

    context "when listing activities exist from RFBs" do
      let(:listing) { given_listing }
      before { given_like(listing, given_registered_user(name: 'Mr RFB')) }

      scenario "user should be able to see stories from everybody" do
        pending('XXXrisingtide: depend once we figure out story creation in acceptance')
        visit_the_everything_feed
        page.should have(2).product_cards
        click_on "Your Likes & Follows"
        page.should have(0).product_cards
      end
    end
  end

  def within_listing_feed(&b)
    within('.listing-feed', &b)
  end

  def within_new_in_network(&b)
    within('.new-in-network', &b)
  end

  def follow_button_should_have_content(content)
    within '.do-follow' do
      page.should have_content(content)
    end
  end

  def generate_new_listing_story
    given_listing(seller: followee.email)
  end

  def visit_the_everything_feed
    login_as user.email
    visit root_path(feed: "everything")
  end

  def product_cards_limit
    Brooklyn::Application.config.feed.defaults.limit
  end
end
