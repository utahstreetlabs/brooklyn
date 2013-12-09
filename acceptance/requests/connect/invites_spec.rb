require './acceptance/spec_helper'

feature "Invite friends" do
  background do
    login_as 'starbuck@galactica.mil'
  end

  context "via email" do
    background do
      visit connect_invites_path
      page.should_not have_success_modal
      open_invite_email_modal
    end

    it "invites friends via email", js: true do
      enter_friend_email_addresses 'apollo@galactia.mil'
      send_email_invites
      wait_a_sec_for_selenium
      page.should have_success_modal
    end

    it "can import email contacts", js: true, fails_in_jenkins: true do
      pending "Quite possibly janrain killed our account so we're just going to remove this feature"
      import_contacts do
        choose_google_accounts do
          sign_into_google_accounts
        end
        select_all_google_accounts_contacts
      end
      should_be_sending_invites_to_imported_contacts
    end
  end

  context 'via facebook', js: true do
    # XXX Uncomment when we unpend; it's a waste to go through the
    # process of creating a Facebook test user here.
    # include_context 'with facebook test user'
    # include_context 'has Facebook friends to invite'
    # include_context 'stubs posting to Facebook wall'

    it "invites friends via facebook", js: true, flakey: true do
      pending "this succeeds on its own but fails in a group. wtf selenium..."
      visit connect_invites_path
      page.should_not have_success_modal
      fb_user_login
      open_invite_fb_modal
      search_for_fb_friends friends.first.name.slice(0, 1)
      wait_a_sec_for_selenium
      select_all_fb_friends
      send_fb_invites
      accept_extended_facebook_permissions
      retry_expectations do
        page.should have_success_modal
      end
    end
  end

  context 'via sharing', js: true do
    background do
      visit connect_invites_path
    end

    context "for facebook" do
      it 'shares invite link to facebook' do
        pending("This somehow causes the next test to fail")
        share_invite_to_facebook
      end
    end

    context "for twitter" do
      it 'shares invite link to twitter' do
        pending("This fails at login_as due to previous test")
        share_invite_to_twitter
      end
    end
  end

  # only used on this page, so don't bother putting it in a support file
  def have_success_modal
    have_css '#invited-modal'
  end
end
