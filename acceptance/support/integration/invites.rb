module InvitesHelpers
  shared_context 'has Facebook friends to invite' do
    let!(:friends) { create_friends_for_current_user(4) }
  end

  shared_context 'stubs posting to Facebook wall' do
    before { Rubicon::FacebookProfile.any_instance.stubs(:post_to_feed).returns(true) }
  end

  FRIEND_NAMES = ['Kara Thrace', 'Lee Adama', 'Bill Adama', 'Laura Roslin', 'Billy Keikeya', 'Anastasia Dualla',
    'Felix Gaeta']

  def random_friend_name
    FRIEND_NAMES[rand(FRIEND_NAMES.count - 1)]
  end

  def create_friends_for_current_user(count = 1)
    (1..count).map do
      first = random_friend_name.split(' ').first
      last = random_friend_name.split(' ').last
      oauth = given_facebook_profile(first_name: first, last_name: last, email: "#{first}.#{last}@galactica.mil",
        uid: "#{rand(10000)}")
      oauth.delete("credentials")
      given_network_follower(current_user.person, :facebook, oauth, true)
    end
  end

  def enter_friend_email_addresses(*addresses)
    fill_in 'Send to', with: addresses.join(', ')
  end

  def send_email_invites
    click_on 'Send Invites'
  end

  def import_contacts(&block)
    click_on 'Import Contacts'
    wait_a_sec_for_selenium
    within_window('Copious: Import your contacts', &block)
  end

  def choose_google_accounts(&block)
    wait_a_sec_for_selenium
    within_frame('rpx_now_embed') { find('#google').click }
    within_window('Google Accounts', &block)
  end

  def sign_into_google_accounts
    fill_in 'Email', with: 'janrain-acceptance-test@copious.com'
    fill_in 'Password', with: 'tugboat792?early'
    click_on 'Sign in'
    wait_a_sec_for_selenium
  end

  def select_all_google_accounts_contacts
    click_on 'Next'
  end

  def should_be_sending_invites_to_imported_contacts
    wait_a_while_for do
      find("#invite_to").value.should have_content('janrain-acceptance-test+me@copious.com')
    end
  end

  def open_invite_fb_modal
    # open_modal doesn't work because we aren't using a standard bootstrap_button modal toggle
    # open_modal(:invite_friends_via_facebook)
    find('[data-invite=facebook]').click
  end

  def open_invite_email_modal
    find('[data-invite=email]').click
  end

  def search_for_fb_friends(search_string)
    within '#fb-friend-search' do
      fill_in 'Find friends:', with: search_string
      click_on 'Search'
    end
  end

  def select_all_fb_friends
    all('#friend-boxes .friend-box').each do |box|
      box.click
    end
  end

  def send_fb_invites
    within '#fb-friend-invite' do
      click_on 'Invite'
    end
  end

  def share_invite_to_facebook
    click_on 'Facebook'
    wait_a_sec_for_selenium
    popup_should_have_facebook_login
    # we can't actually do Facebook stuff, so if we get here, we're done
  end

  def share_invite_to_twitter
    click_on 'Twitter'
    wait_a_sec_for_selenium
    popup_should_have_twitter_login
    # we can't actually do Twitter stuff, so if we get here, we're donea
  end
end

RSpec.configure do |config|
  config.include InvitesHelpers
end
