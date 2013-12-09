require 'rubicon/models/profile'

class Profile < LadonDecorator
  include Brooklyn::Sprayer
  decorates Rubicon::Profile

  def to_param
    id
  end

  def belongs_to_user?(user)
    user.id == self.user_id
  end

  def person
    @person ||= Person.where(id: self.person_id).first
  end

  def user
    unless defined?(@user)
      @user = person && person.user
    end
    @user
  end

  def user=(user)
    self.person_id = user.person.id
  end

  def identity
    @identity ||= Identity.find_by_provider_id(self.network, self.uid)
  end

  def connected?
    !!identity
  end

  def can_disconnect?
    self.connected?
  end

  def disconnect!
    # the memoized identity doesn't raise exceptions on service errors, so to
    # to support that here, we ensure that a nil is the result of an absent identity
    # and not a service error
    id = identity || Identity.find_by_provider_id!(self.network, self.uid)
    id.delete! if id
  end

  def unregister!
    disconnect!
    decorated.unregister!
  end

  def ranked?
    !!ranked_at
  end

  def synced?
    !!synced_at
  end

  def update_from_oauth!(user, auth)
    args = []
    if self.connected?
      raise ExistingConnectedProfile unless user.nil? || user.person_id == self.person_id
      raise InvalidCredentials unless self.valid_credentials?(auth)
    else
      if user && self.person_id != user.person_id
        args << user.person_id
        begin
          Person.destroy(self.person_id)
        rescue ActiveRecord::StatementInvalid => e
          # somewhat harmless to leave the stray person behind
        end
      end
    end
    super(auth, *args)
  end

  def sync
    super { Person.create!.id }
  end

  def async_sync
    Profiles::SyncAll.enqueue(self.person_id, self.uid, self.network)
  end

  def async_sync_attrs
    Profiles::SyncAttrs.enqueue(self.person_id, self.uid, self.network)
  end

  def inviters_following(followee_profile_or_id)
    super(followee_profile_or_id.is_a?(self.class) ? followee_profile_or_id.id : followee_profile_or_id)
  end

  def uninvited_followers(options = {})
    super.map { |p| self.class.new(p) }
  end

  def pending_u2u_invites
    if network == Network::Facebook.symbol
      FacebookU2uInvite.find_all_pending(self.uid)
    end
  end

  def self.create!(person_id, network, attrs = {})
    klass = profile_class(network)
    decorated = klass.create!(person_id, network, attrs)
    decorated && new(decorated)
  end

  def self.create_from_oauth!(person_id, network, auth)
    decorated = super
    decorated && new(decorated)
  end

  def self.find(profile_or_id)
    super(profile_or_id.is_a?(Profile) ? profile_or_id.id : profile_or_id)
  end

  def self.find_for_uid_and_network(uid, network)
    decorated = super
    decorated && new(decorated)
  end

  def self.find_for_people_and_network(person_ids, network, params = {})
    super(person_ids, network.to_sym, params).map { |p| new(p) }
  end

  def self.find_for_person_and_network(person, network, params = {})
    decorated = super(person.id, network, params)
    decorated && new(decorated)
  end

  def self.find_all_for_person(person_id, options = {})
    super.map { |p| new(p) }
  end

  def self.find_all_for_person!(person_id, options = {})
    super.map { |p| new(p) }
  end

  def self.async_sync(person, uid, network)
    Profiles::SyncAll.enqueue(person.id, uid, network)
  end
end
