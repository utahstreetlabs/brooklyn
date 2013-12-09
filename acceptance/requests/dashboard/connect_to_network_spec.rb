require './acceptance/spec_helper'

feature "Connect to Twitter from dashboard", %q{
  In order to build signal
  As a registered user
  I want to connect my Twitter profile to my Copious account
} do

  background do
    given_twitter_profile
    login_as "starbuck@galactica.mil"
  end

  scenario "connect happily", js: true do
    visit dashboard_path
    connect_to 'Twitter'
    connection_should_succeed 'Twitter'
  end
end

feature "Connect to Tumblr from dashboard", %q{
  In order to build signal
  As a registered user
  I want to connect my Tumblr profile to my Copious account
} do

  background do
    given_tumblr_profile
    login_as "starbuck@galactica.mil"
  end

  scenario "connect happily", js: true do
    visit dashboard_path
    connect_to 'Tumblr'
    connection_should_succeed 'Tumblr'
  end
end

feature "Connect to Facebook from dashboard", %q{
  In order to build signal
  As a registered user
  I want to connect my Facebook profile to my Copious account
} do

  include_context 'with facebook test user'

  background do
    # fake twitter, real facebook.  tricky.
    with_mocked_oauth { register_with_twitter }
  end

  scenario "connect happily", js: true do
    visit dashboard_path
    fb_user_login fb_user, return_to: for_sale_dashboard_path
    connect_to 'Facebook'
    connection_should_succeed 'Facebook'
  end
end

feature "Connect to Instagram from dashboard", %q{
  In order to build signal
  As a registered user
  I want to connect my Instagram profile to my Copious account
} do

  background do
    given_instagram_profile
    login_as "starbuck@galactica.mil"
  end

  scenario "connect happily", js: true do
    visit dashboard_path
    connect_to 'Instagram'
    connection_should_succeed 'Instagram'
  end

  scenario "connect happily via ssl", js: true do
    ActionDispatch::Request.any_instance.stubs(:ssl?).returns(true)
    visit for_sale_dashboard_path
    connect_to 'Instagram'
    connection_should_succeed 'Instagram'
  end
end
