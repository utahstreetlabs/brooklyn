require './acceptance/spec_helper'

feature "Earn offer" do
  include_context 'buyer signup'

  let(:offer) { given_offer }

  context "when earning offers", js: true do
    include_context "with disconnected facebook test user"
    # include_context "mock facebook profile"

    before do
      visit root_path
      fb_user_login
    end

    context "for new user" do
      background do
        Person.any_instance.stubs(:minimally_connected?).returns(true)
      end

      context "when offer allows new users" do
        it "grants the user the offer credits" do
          visit offer_path(offer.uuid)
          click_facebook_signup
          add_copious_to_facebook
          proceed_through_buyer_flow
          page.should indicate_offer_granted
        end
      end

      context "when offer doesn't allow new users" do
        let(:offer) { given_offer(new_users: false) }

        it "doesn't grant the user the offer credits" do
          visit offer_path(offer.uuid)
          click_facebook_signup
          add_copious_to_facebook
          proceed_through_buyer_flow
          page.should have_content("only available to existing users")
        end
      end
    end

    context "for registered user" do
      background do
        Person.any_instance.stubs(:minimally_connected?).returns(true)
        visit root_path
        click_facebook_connect
        add_copious_to_facebook
        complete_full_registration
      end

      context "when logged out" do
        background do
          visit logout_path
          visit offer_path(offer.uuid)
          # user will be auto-logged in.
          # uncomment the next line if autologin is turned off in test.
          # click_facebook_signup
        end

        context "when offer allows existing users" do
          it "grants the user the offer credits" do
            retry_expectations { page.should indicate_offer_granted }
          end

          it "doesn't attempt to grant the offer twice" do
            retry_expectations { page.should indicate_offer_granted }
            login_as 'johnny@thewinters.com', logout: true
            page.should_not have_content('orry')
          end
        end

        context "when offer doesn't allow existing users" do
          let(:offer) { given_offer(existing_users: false) }

          it "doesn't grant credits" do
            retry_expectations { page.should have_content("only available to new Copious users") }
          end
        end
      end

      context "when logged in" do
        it "grants the user the offer credits" do
          visit offer_path(offer.uuid)
          page.should indicate_offer_granted
        end
      end
    end
  end

  RSpec::Matchers.define :indicate_offer_granted do
    match do |page|
      page.has_content?("credit has been added to your account.")
    end
  end
end
