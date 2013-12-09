require './acceptance/spec_helper'

feature 'Sign up from an invite' do
  include_context 'buyer signup'
  include_context 'with facebook test user' # defines fb_user

  let!(:inviter) { given_registered_user email: 'starbuck@galactica.mil', name: 'Kara Thrace' }
  let!(:api_user) { stub 'api_user', has_permission?: true }
  # why does fb_user not have first or last names?
  let!(:oauth) { given_facebook_profile(uid: fb_user.id, first_name: "First", last_name: "Last", email: fb_user.email) }
  let(:oauth_nocreds) do
    auth = oauth.dup
    auth.delete("credentials")
    auth
  end

  background do
    api_user.stubs(:friends).returns(Credit.min_invitee_followers.times.map {|n| stub("follower #{n}", id: n)})
    Rubicon::FacebookProfile.any_instance.stubs(:api_user).returns(api_user)
  end

  context "When accepting an untargeted invite" do
    let!(:invite) { given_untargeted_invite inviter }

    scenario "Both the inviter and I should get credit", js: true do
      accept_invite(false)
      visit settings_credits_path
      page.should have_credit
      buy_something
      login_as_inviter
      visit settings_credits_path
      page.should have_credit
    end

    scenario "Neither of us get credit when I am not minimally connected", js: true do
      api_user.stubs(:friends).returns([])
      accept_invite(false)
      page.should have_top_message(:invalid_user_connectivity)
      visit settings_credits_path
      page.should_not have_credit
      buy_something
      login_as_inviter
      visit settings_credits_path
      page.should_not have_credit
    end

    scenario "Neither of us should get credit when the inviter is capped", js: true do
      Invite.stubs(:max_creditable_acceptances).returns(0)
      accept_invite(false)
      page.should have_top_message(:invitee_invite_capped)
      visit settings_credits_path
      page.should_not have_credit
      buy_something
      login_as_inviter
      visit settings_credits_path
      page.should_not have_credit
    end
  end

  context "When accepting a direct invite" do
    let!(:invited_profile) do
      given_directly_invited_profile_from inviter.person.for_network(:facebook), invitee_oauth: oauth_nocreds
    end
    let!(:invite) { invited_profile.invites.first }

    scenario "Both the inviter and I should get credit", js: true do
      accept_invite(true)
      visit root_path
      page.should have_following_inviter_story
      visit settings_credits_path
      page.should have_credit
      buy_something
      login_as_inviter
      visit root_path
      page.should have_invite_accepted_stories
      visit settings_credits_path
      page.should have_credit
    end

    scenario "Neither of us get credit when I am not minimally connected", js: true do
      api_user.stubs(:friends).returns([])
      accept_invite(true)
      page.should have_top_message(:invalid_user_connectivity)
      visit settings_credits_path
      page.should_not have_credit
      buy_something
      login_as_inviter
      visit settings_credits_path
      page.should_not have_credit
    end

    scenario "Neither of us should get credit when the inviter is capped", js: true do
      Invite.stubs(:max_creditable_acceptances).returns(0)
      accept_invite(true)
      page.should have_top_message(:invitee_invite_capped)
      visit settings_credits_path
      page.should_not have_credit
      buy_something
      login_as_inviter
      visit settings_credits_path
      page.should_not have_credit
    end
  end

  def accept_invite(targeted = false)
    visit invite_path(invite)
    fb_user_login
    click_facebook_connect
    accept_insane_gdp_facebook_permissions
    proceed_through_buyer_flow
    should_be_on_home_page
  end

  def have_top_message(key = nil)
    selector = '[data-role=top-message]'
    selector << "[data-key='#{key}']" if key
    have_css(selector)
  end

  def have_credit
    have_css('[data-role=credit-amount]')
  end

  def have_following_inviter_story
    # XXX when we figure out risingtide in acceptance
  end

  def buy_something
    simulate_purchase as: User.find_by_email(fb_user.email)
  end

  def login_as_inviter
    login_as inviter.email, logout: true
  end

  def have_invite_accepted_stories
    # XXX when we figure out risingtide in acceptance
  end
end
