# -*- coding: utf-8 -*-
require './acceptance/spec_helper'

feature 'Signup offer' do
  include_context 'signup credit offers exist'

  context 'from the home page', js: true do
    before { visit root_path }

    context 'when connecting with twitter' do
      before do
        given_twitter_profile
        click_twitter_connect
      end

      scenario 'the user should be notified that they earned a credit' do
        complete_full_registration
        should_be_granted_signup_credit
      end
    end

    context 'logging in with an existing user' do

      scenario 'the user should not be notified that they did not earn a credit' do
        login_as('starbuck@galactica.mil')
        page.should_not have_flash_message(:notice, 'controllers.offer_earnable.invalid_new_only')
      end
    end
  end

  def should_be_granted_signup_credit
    current_user.credit_balance.should == signup_offer_amount
  end
end
