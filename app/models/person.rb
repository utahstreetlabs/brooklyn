class ExistingConnectedProfile < Exception; end
class InvalidCredentials < Exception; end
class ConnectionFailure < Exception; end

class Person < ActiveRecord::Base
  include People::Shareable
  include Brooklyn::Observable

  has_one :user, :dependent => :destroy

  # after_create { Brooklyn::Redhook.async_create_person(id) }

  UNINVITED_MULTIPLIER = 20

  def registered?
    self.user.present? && self.user.registered?
  end

  def display_name
    self.user && self.user.display_name
  end

  def network_profiles(reload = false)
    return @network_profiles if @network_profiles and !reload
    logger.debug("Loading profiles for user #{self.id}")
    # we currently have a slightly confusing model where we leave a profile connected to a person when it gets
    # disconnected, then a user can connect a different network
    # in order to allow assumptions elsewhere to work, we ensure that if there is a connected network, that's the one
    # that gets returned (by sorting to the end as only one of each is stored in the network_profiles hash)
    sorted = Profile.find_all_for_person(self.id, connection_count: true).sort_by { |p| p.connected?? 1 : -1 }
    @network_profiles = sorted.each_with_object({}) do |profile, map|
      if profile.type
        key = "#{profile.network}_#{profile.type}".to_sym
        if Network.klass(key).active?
          map[key] ||= []
          map[key] << profile
        end
      else
        map[profile.network] = profile if Network.klass(profile.network).active?
      end
    end
    @network_profiles
  end

  def for_network(network)
    network_profiles[network.to_sym]
  end

  def connected_to?(network)
    p = for_network(network)
    p && p.connected?
  end

  # Returns the list of networks to which this person is connected.
  def connected_networks
    network_profiles.reject {|key, profiles| Array.wrap(profiles).find {|p| !p.connected?}}.keys
  end

  def connected_profiles
    network_profiles.flat_map {|key, profiles| Array.wrap(profiles).find {|p| p.connected?}}.find_all {|p| not p.nil?}
  end

  # Returns true if at least one of the person's untyped connected networks has at least +minimum+ followers.
  # Warning: fetches follower counts from each connected network until it finds one that meets the criteria (if any),
  # so is comparatively slow.
  def minimally_connected?(minimum, options = {})
    untyped = connected_profiles.select { |p| p.type.nil? }
    connected = untyped.any? { |p| p.connection_count >= minimum }
    # in some cases (all?) we want to give the benefit of the doubt and assume the user is minimally connected if we
    # can't connect to facebook or whatever external service we are trying to validate against
    connected ||= begin
      untyped.any? { |p| p.fetch_api_followers.count >= minimum }
    rescue Exception => e
      options[:permit_on_error] ? true : raise
    end
    connected
  end

  def async_sync_connected_profiles
    Profiles::SyncEach.enqueue(self.id)
  end

  # Returns a list of networks for which a person is missing required permissions
  # (as specified by our configuration)
  def missing_required_network_permissions
    Network.active.inject([]) do |m, n|
      missing_required_permissions(n).any? ? m.concat(Array.wrap(n)) : m
    end
  end

  def missing_required_permissions(network)
    missing_permissions(network, Network.klass(network).required_permissions)
  end

  def missing_permissions(network, required = [])
    profile = for_network(network)
    profile.present?? required.reject { |p| profile.has_permission?(p) } : required
  end

  # Returns the highest-value network profile for this person relative to the profiles another person is connected to.
  # Highest-value in this context means that 1) the other person is not connected to the network and 2) it is this
  # person's profile with the highest connection count. If the other person is connected to every network that this
  # person is (or this person is not connected to any networks), or if the highest value profile has 0 connections,
  # returns +nil+.
  def find_highest_value_network_profile(other)
    candidate_networks = connected_networks - other.connected_networks
    if candidate_networks.any?
      candidate_networks.
        map {|network| for_network(network)}.
        inject([]) {|m, ps| m.concat(Array.wrap(ps).select {|p| p.connection_count > 0})}.
        sort {|a, b| b.connection_count <=> a.connection_count}.
        first
    else
      nil
    end
  end

  def blacklist_invite_suggestion(profile_id)
    logger.debug("Blacklisting invite suggestion for profile #{profile_id}")
    Lagunitas::Preferences.add(user.id, :invite_suggestion_blacklist, profile_id)
  end

  def invite_suggestion_blacklist
    user.preferences.invite_suggestion_blacklist
  end

  # Returns suggestions for network friends/followers to invite to Copious. Returns up to +limit+ network profiles
  # that meet the following criteria:
  #
  # * Following this person in the external network
  # * Not associated with a registered Copious user
  # * Has not already been invited to Copious by this person
  #
  # Note: only suggests Facebook friends at the moment. If the person is not connected to Facebook, returns an empty
  # list.
  def invite_suggestions(limit = 3, options = {})
    logger.debug("Loading #{limit} invite suggestions for person #{self.id}")
    facebook_profile = for_network(Network::Facebook.symbol)
    if facebook_profile && facebook_profile.connected?
      fetch_suggestions(facebook_profile, limit, options.merge(num_suggestions: limit))
    else
      logger.info("Person #{self.id} not connected to Facebook; no invite suggestions provided")
      []
    end
  end

  # Choose the first N uninvited follower profiles, filter out the ones that are actually registered users,
  # and take up to limit of the remaining users.  If we don't get enough suggestions, fetch more starting
  # at an offset.
  #
  # @param [Profile] profile the profile of the user for which follower profiles are fetched
  # @param [Integer] limit the number of results to return for the followers query
  # @option options [Integer] :offset (0) the position in the followers query results to start
  # @option options [Integer] :num_suggestions (+limit+) the number of suggestions to return; may be different than
  #   the limit, if a smaller number of results are required (only necessary when called recursively)
  # @option options [Array] :blacklist profile ids to filter from the followers query results
  # @option options [String] :name profile name to filter from the followers query results
  def fetch_suggestions(profile, limit, options = {})
    blacklist = (options[:blacklist] || []) + invite_suggestion_blacklist

    # fetch more suggestions than necessary in case we need to prune some out due to blacklist or users
    # who are already registered.
    num_suggestions = options[:num_suggestions] || limit
    offset = options[:offset] || 0
    # :invites are fetched here with the profiles so that we can determine if the suggestion is a
    # pile on invite; if any profile contains an invite from a friend, the invite is a pile on.
    friend_profiles = profile.uninvited_followers(name: options[:name], limit: limit, offset: offset,
      fields: [:network, :person_id, :uid, :name, :profile_url, :photo_url, :invites])
    unless friend_profiles.any?
      logger.debug("No uninvited friend profiles found for person #{id})")
      return []
    end

    registered_users = User.where(person_id: friend_profiles.map(&:person_id)).with_state(:registered).
      inject({}) {|m, u| m.merge(u.person_id => u)}
    registered_profiles = friend_profiles.find_all {|f| !registered_users.include?(f.person_id)}
    unless registered_profiles.any?
      logger.debug("No registered friend profiles found for person #{id}")
    end

    whitelisted_profiles = registered_profiles.reject {|f| blacklist.include?(f.id)}
    unless whitelisted_profiles.any?
      logger.debug("No whitelisted friend profiles found for person #{id}")
    end

    suggestions = whitelisted_profiles.take(num_suggestions)
    unless suggestions.any?
      logger.debug("No suggestions found for person #{id}")
    end

    # After removing any profiles we don't want to include, if we still need more, ask for more.
    return suggestions if options[:dont_ask_for_more]
    return suggestions unless suggestions.size < num_suggestions
    return suggestions if friend_profiles.size < limit
    offset = options[:offset] ? options[:offset] + limit : limit
    more_options = options.merge(offset: offset, num_suggestions: num_suggestions - suggestions.size)
    suggestions.concat(fetch_suggestions(profile, limit, more_options))
  end

  # Sends an invitation to a person on an external network and records the invite in Rubicon. Returns the invite, or
  # +nil+ if the invite couldn't be sent or saved for some reason.
  def invite!(invitee_id, invite_url_generator, options = {})
    invitee = Profile.find(invitee_id)
    unless invitee
      logger.warn("Person #{self.id} cannot invite profile #{invitee_id}: no such invitee")
      return nil
    end

    if invitee.connected?
      logger.warn("Person #{self.id} cannot invite profile #{invitee.id}: invitee already connected to #{invitee.network}")
      return nil
    end

    missing_permissions = missing_required_permissions(invitee.network)
    if missing_permissions.any?
      # XXX: raise MissingPermission when we can handle those by asking the user to reconnect
      logger.warn("Person #{self.id} cannot invite profile #{invitee.id} on #{invitee.network}: missing permissions #{missing_permissions.join(', ')}")
      return nil
    end

    inviter = for_network(invitee.network)
    unless inviter && inviter.connected?
      logger.warn("Person #{self.id} cannot invite profile #{invitee.id} on #{invitee.network}: inviter not connected")
      return nil
    end

    logger.debug("Creating #{invitee.network} invite from #{inviter.name} (#{inviter.id}) to #{invitee.name} (#{invitee.id})")
    invite = invitee.create_invite_from(inviter)
    unless invite
      logger.warn("Person #{self.id} could not create invite for profile #{invitee.id} on #{invitee.network}")
      return nil
    end

    logger.debug("Sending #{invitee.network} invitation from #{inviter.name} (#{inviter.id}) to #{invitee.name} (#{invitee.id})")
    invite_params = {link: invite_url_generator.call(invite), firstname: self.user.firstname, invitee_firstname: invitee.first_name || invitee.name}
    invite_params.merge!(options[:params]) if options[:params]
    invite_opts = invite_options(invitee.network, invite_params)
    unless invitee.send_invitation_from(inviter, invite, invite_opts)
      logger.warn("Person #{self.id} could not send invitation to profile #{invitee.id} on #{invitee.network}")
      return nil
    end

    PersonObserver.after_invite_sent(self, invitee)
    invite
  end

  def build_user_from_network_profile(network, options = {})
    user = build_user(options[:user])
    user.update_from_profile(for_network(network))
    user
  end

  # XXX: need to use self here due to insane mid-stream scope switching in ruby.
  def get_or_create_user_from_network_profile(network, scope, options = {})
    unless self.user.present?
      user = build_user_from_network_profile(network, options)
      begin
        self.user = user
        self.user.connect # XXX: capture and log errors
        notify_observers(:after_profile_update, network, scope: scope)
      rescue ActiveRecord::RecordNotSaved => e
        logger.error("Could not save person's user: #{user.errors.inspect}")
        raise
      end
    end
    self.user
  end

  def update_oauth_token(network, options = {})
    network = network.to_sym
    profile = for_network(network)
    return unless profile

    attrs = options.select { |k, v| [:token, :secret].include?(k) }
    if profile.valid_credentials?(attrs)
      profile.update_attributes!(attrs)
    else
      logger.warn("Invalid credentials for (profile=>#{profile.id}, network=>#{network}, attrs=>#{attrs.inspect}")
    end
  end

  def create_or_update_profile_from_oauth(network, auth)
    network = network.to_sym
    profile = Profile.find_for_uid_and_network(auth['uid'], network)
    raise InvalidCredentials if profile && !profile.valid_credentials?(auth)
    if profile && (profile.person_id != self.id)
      # Profile exists in this network for this uid; examine the person attached
      # to the profile and see if it's not us; it could be a dummy follower or
      # another registered user that has already connected with it.
      begin
        other_person = Person.find(profile.person_id)
      rescue ActiveRecord::RecordNotFound => e
        other_person = nil
      end
      if other_person
        unless other_person.registered?
          # If it's not a registered user, nuke the Person from mysql and rubicon
          Profile.delete!(profile.person_id, network)
          begin
            Person.destroy(profile.person_id)
          rescue ActiveRecord::StatementInvalid => e
            # We can get a statement invalid exception trying to destroy a person and due
            # to a foreign key constraint ActiveRecord won't let us (another table referencing
            # this person).  We catch the error here and leave the person, which isn't causing
            # us any trouble.  Since we've deleted the profile in rubicon, we can now bind a new
            # profile to our person for this network and uid.
          end
          # If a profile already exists for this person, update it from rubicon
          # Otherwise create a new profile.
          profile = Profile.find_for_person_and_network(self, network)
          if profile
            profile.update_from_oauth!(self.user, auth)
          else
            profile = Profile.create_from_oauth!(self.id, network, auth)
          end
        else
          # Other profile was attached to a registered user.  If the other profile
          # does not have auth tokens, go ahead and use it for us.
          raise ExistingConnectedProfile if profile.connected?

          # If we already have a profile stored in rubicon for this person &
          # network, perhaps because we were attached using a different account, use that.
          existing_profile = Profile.find_for_person_and_network(self, network)
          # If we have a profile that already belongs to us, just use it.
          if existing_profile
            profile = existing_profile
          else
            # Just use the profile we found for the uid/network combination; update the person_id
            # to be our person id.
            profile.person_id = self.id
          end
          profile.update_from_oauth!(self.user, auth)
        end
      else
        # No other person could be found for the other profile.  Nuke the
        # profile from Rubicon and then create a new profile for our user.
        Profile.delete!(profile.person_id, network)
        profile = Profile.create_from_oauth!(self.id, network, auth)
      end
    else
      # Use the cached profile if available.
      profile ||= for_network(network)
      if profile
        profile.update_from_oauth!(self.user, auth)
      else
        profile = Profile.create_from_oauth!(self.id, network, auth)
      end
    end
    notify_observers(:after_profile_update, network, scope: auth['scope'])
    network_profiles[network] = profile
    profile
  end

  def redhook_person
    @redhook_person ||= Brooklyn::Redhook.find_person(self.id)
  end

  # no network returns the total, which is a count of *distinct* people and therefore may be less than the sum
  # of each network-specific count. Returns nil if there is an error connecting to the service.
  def connection_count(network=nil)
    rhp = redhook_person
    rhp ? rhp.connection_count(network) : nil
  end

  # A user is considered eligible to sign up for timeline if they have connected
  # to facebook, they have not granted the "publish_actions" extended permission,
  # they have not opted out of the facebook_timeline feature in their preferences.
  def eligible_for_facebook_timeline?(options = {})
    # Check preferences first before contacting rubicon (and facebook)
    return false unless options[:force_request] || self.user.allow_feature?(:request_timeline_facebook)
    profile = for_network(:facebook)
    # If we locally don't think we have the publish_actions permission, then we
    # are eligible for adding the timeline.
    return true if profile && !profile.has_permission?(:publish_actions)
    begin
      profile ? !profile.has_live_permission?(:publish_actions) : false
    rescue Timeout::Error => e
      # If we get a timeout talking to Facebook, we don't want to consider the user
      # eligible for timeline.
      logger.warn("Timeout getting permission from facebook, person => #{self.id}: #{e.message}")
      false
    rescue Exception => e
      logger.info("Unable to fetch facebook publish_actions permission for person=>#{self.id}: #{e.message}")
      false
    end
  end

  def connected_network_profile(network)
    connected_to?(network) && for_network(network)
  end

  def self.find_or_create_from_uid_and_network(uid, network, auth)
    profile = Profile.find_for_uid_and_network(uid, network)
    person = profile ? Person.find(profile.person_id) : Person.create!
    person.create_or_update_profile_from_oauth(network, auth)
    person
  end

  def self.find_by_network_id(uid, network)
    network = network.to_sym
    profile = Profile.find_for_uid_and_network(uid, network)
    Person.find(profile.person_id) if profile
  end

  def self.connect_from_oauth(network, auth)
    if person = find_by_network_id(auth['uid'], network)
      person.create_or_update_profile_from_oauth(network, auth)
      person
    else
      Person.find_or_create_from_uid_and_network(auth['uid'], network, auth)
    end
  end

  # Finds a person object using +email+ searching (in order):
  #  * User.email
  #  * Rubicon Profile email
  #  * EmailAccount.email
  # Returns based on first one found
  def self.find_by_any_email(email)
    find_by_user_email(email) || find_by_profile_email(email) || find_by_email_account(email)
  end

  def self.find_by_user_email(email)
    joins(:user).where(User.table_name => {email: email}).first
  end

  def self.find_by_email_account(email)
    account = EmailAccount.find_by_email(email, :include => :user)
    account.user.person if account && account.user
  end

  def self.find_by_profile_email(email)
    profile = Profile.find_by_email(email).first
    Person.find(profile.person_id) if profile
  end

protected
  def invite_options(network, params = {})
    Network.klass(network).message_options!(:invite_with_credit, params)
  end
end
