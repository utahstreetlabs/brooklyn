require './acceptance/spec_helper'

feature "Follow a seller", %q{\n
  As a buyer interested in a seller
  To follow interesting events related to that seller
  I want to follow the seller
} do

  let!(:listing) { FactoryGirl.create(:active_listing) }

  include_context 'suppress signup follows'

  scenario "Follow a seller", js: true do
    login_as "starbuck@galactica.mil"
    visit listing_path(listing)
    page.find("#listed-by-seller-followers-count-#{listing.seller.id}").text.strip.to_i.should == 0
    find('[data-action=follow]').click
    page.should have_css('[data-action=unfollow]')
    page.find("#listed-by-seller-followers-count-#{listing.seller.id}").text.strip.to_i.should == 1
  end
end

feature "Unfollow a seller", %q{\n
  As a busy and overwhelmed user
  To cut down on the noise in my activity stream
  I want to unfollow a seller I do not care about
} do

  let!(:listing) { FactoryGirl.create(:active_listing) }

  include_context 'suppress signup follows'

  scenario "Unfollow a seller", js: true do
    login_as "starbuck@galactica.mil"
    given_organic_follow(listing.seller, current_user)
    visit listing_path(listing)
    page.find("#listed-by-seller-followers-count-#{listing.seller.id}").text.strip.to_i.should == 1
    find('[data-action=unfollow]').click
    page.should have_css('[data-action=follow]')
    page.find("#listed-by-seller-followers-count-#{listing.seller.id}").text.strip.to_i.should == 0
  end
end
