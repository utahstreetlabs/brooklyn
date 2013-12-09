require './acceptance/spec_helper'
require 'timecop'

feature "LIH hot or not", js: true do
  context "with flag enabled" do
    feature_flag('home.logged_in.hot_or_not', true)

    scenario "is shown" do
      stub_ab_test(:logged_in_home_hot_or_not, :on_1)
      given_listing
      # a test user created right now with no likes should trigger the process
      login_as("starbuck@galactica.mil")
      modal_should_be_visible('hot-or-not')
    end
  end

  context "with flag disabled" do
    feature_flag('home.logged_in.hot_or_not', false)

    scenario "is not shown" do
      login_as("starbuck@galactica.mil")
      modal_should_not_exist('hot-or-not')
    end
  end
end
