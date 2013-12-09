require './acceptance/spec_helper'
require 'timecop'

feature "LIH collection carousel" do
  let!(:listings) do
    Brooklyn::Application.config.home.collection_carousel.min_listings.times.map do
      FactoryGirl.create(:active_listing, approved: true)
    end
  end
  let(:users) { FactoryGirl.create_list(:registered_user, 2) }

  background do
    users.first.collections.each do |collection|
      collection.add_listings(listings.map(&:id))
      users.second.follow_collection!(collection)
    end
  end

  context "with flag enabled" do
    feature_flag('home.logged_in.collection_carousel', true)

    scenario "is shown" do
      login_as(users.second.email)
      page.should have(users.first.collections.size).collection_cards
    end
  end

  context "with flag disabled" do
    feature_flag('home.logged_in.collection_carousel', false)

    scenario "is not shown" do
      login_as(users.second.email)
      page.should have(:no).collection_cards
    end
  end
end
