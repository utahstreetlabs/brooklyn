require 'flying_dog/models/identity'

class Identity < LadonDecorator
  include ActiveModel::Observing
  include Brooklyn::Observable
  decorates FlyingDog::Identity

  attr_accessor :profile

  # Get the rubicon profile associated with this identity
  def profile
    @profile ||= Profile.find_for_uid_and_network(self.uid, self.provider)
  end

  def user
    @user ||= User.where(id: self.user_id).first
  end

  def person
    @person ||= (user && user.person)
  end

  def belongs_to_user?(user)
    self.user_id == user.id
  end

  def update_from_oauth!(oauth)
    decorated = super
    Identity.notify_observers(:after_update_from_oauth, self) if decorated
    self
  end

  def self.find_by_provider_id!(provider, uid)
    # sometimes we get a symbol, sometimes we get a Network::Base subclass
    provider = provider.symbol if provider.respond_to?(:symbol)
    decorated = super(provider, uid)
    decorated && new(decorated)
  end

  def self.find_by_provider_id(provider, uid)
    find_by_provider_id!(provider, uid)
  rescue Exception => e
    nil
  end

  def self.create_from_oauth!(user, provider, oauth)
    decorated = super(user.id, provider.symbol, oauth)
    identity = decorated && new(decorated)
    # XXX: unfortunately, using a standard hook like +:after_create+ requires dragging in a bunch of active model's
    # deeply assumption-laden code base and restructuring our ladon decorator model to match
    notify_observers(:after_update_from_oauth, identity)
    identity
  end
end
