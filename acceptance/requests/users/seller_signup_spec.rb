require './acceptance/spec_helper'

feature 'Seller signup' do
  # there's no twitter button on the create listing page, only facebook
  context 'with an unconnected facebook user' do
    include_context 'with disconnected facebook test user'

    context 'signing up from the create listing page' do
      before do
        # XXX: currently no link off the homepage, so go directly to new listing page
        # visit root_path
        # click_on 'List my stuff'
        given_facebook_profile
        visit new_listing_path
        @original_path = current_path
      end

      scenario 'proceeds through the seller flow and drops the user back on the create listing page', js: true do
        fb_user_login
        click_facebook_connect
        add_copious_to_facebook
        complete_full_registration
        current_path.should == @original_path
      end
    end
  end
end
