class UserMailer < MailerBase
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  helper :application, :connection_digest

  # Returns a mail message for +user+ containing reset password instructions.
  def reset_password_instructions(user)
    @user = user
    setup_mail(:reset_password_instructions, :headers => {:to => @user.email})
  end

  def invite(inviter, address, message)
    @user = inviter
    @address = address
    @message = message
    campaign = 'invite'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:invite, :headers => {:to => @address}, :params => {name: inviter.name})
  end

  def invite_accepted(inviter, invitee_attrs)
    @inviter = inviter
    @invitee = attrs_hash(invitee_attrs)
    campaign = 'inviteaccepted'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:invite_accepted, headers: {to: inviter.email}, params: {invitee: invitee_attrs[:name]})
  end

  def welcome_1(user)
    @user = user
    campaign = 'welcome1'
    category = 'welcome'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    setup_mail(:welcome_1, headers: {to: user.email}, params: {name: user.firstname})
  end

  def welcome_2(user)
    @user = user
    campaign = 'welcome2'
    category = 'welcome'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    setup_mail(:welcome_2, headers: {to: user.email}, params: {})
  end

  def welcome_3(user)
    @user = user
    campaign = 'welcome3'
    category = 'welcome'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    setup_mail(:welcome_3, headers: {to: user.email}, params: {})
  end

  def welcome_4(user)
    @user = user
    campaign = 'welcome4'
    category = 'welcome'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    setup_mail(:welcome_4, headers: {to: user.email}, params: {})
  end

  def welcome_5(user)
    @user = user
    campaign = 'welcome5'
    category = 'welcome'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    setup_mail(:welcome_5, headers: {to: user.email}, params: {})
  end

  def friend_joined(friend, id_or_attrs)
    @friend = friend
    @follower = find_user(id_or_attrs)
    campaign = 'friendjoin'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:friend_joined, headers: {to: @follower.email}, params: {friend: friend.name})
  end

  def draft_listing_reminder(user, listing)
    @user = user
    @listing = listing
    campaign = 'draftlisting'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:draft_listing_reminder, headers: {to: user.email}, params: {name: user.firstname})
  end

  def invitee_purchase_credit(inviter, invitee_attrs)
    @inviter = inviter
    @invitee = attrs_hash(invitee_attrs)
    @referral_credit_amount = smart_number_to_currency(Brooklyn::Application.config.credits.inviter.amount)
    campaign = 'inviteepurchasecredit'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:invitee_purchase_credit, headers: {to: inviter.email}, params: {invitee: invitee_attrs[:name], credit_amount: @referral_credit_amount})
  end

  # @param [Hash] listings_and_likers a map from listings to the ids of users who have liked that listing
  def connection_digest(user, listings_and_likers)
    @user = user

    @listings = listings_and_likers.keys
    @like_counts = Listing.like_counts(@listings.map(&:id))
    @suggestion_strips = UserStripCollection.new(user, user.follow_suggestions(50).sample(4))

    # compute names to use in the email subject
    closest_friends = user.closest_friends_among(listings_and_likers.values.inject(&:union).to_a, limit: 3)
    names = closest_friends.empty? ? t('mailers.user.connection_digest.names_default') : closest_friends.map(&:firstname).to_sentence

    campaign = 'cdigest'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    split_test_with user.visitor_id, :cdigest_clickthroughs
    setup_mail(:connection_digest,
      headers: {to: user.email, from: from_email(name: t('mailers.user.connection_digest.from_name'))},
      params: {names: names, count: closest_friends.count},
      subject_ab_test_key: :connection_digest_r2)
  end

  protected

    # backwards compatibility - load a user from an id or a hash of params
    # including a slug
    def find_user(id_or_attrs)
      if id_or_attrs.is_a? Hash
        User.find_by_slug(id_or_attrs[:slug])
      else
        User.find(id_or_attrs)
      end
    end
end
