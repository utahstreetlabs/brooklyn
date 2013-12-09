class Session
  extend ActiveModel::Naming
  include ActiveModel::Observing

  attr_reader :user, :storage
  delegate :[], :[]=, :delete, :to_hash, :logger, to: :storage

  def initialize(storage = {})
    @storage = storage
  end

  def sign_in(user)
    @user = user
    notify_observers(:before_sign_in)
    @storage[:user_id] = @user.id
    self.touch!
    notify_observers(:after_sign_in)
  end

  def sign_out
    notify_observers(:before_sign_out)
    @storage.keys.reject { |key| key.to_s == '_csrf_token' }.each { |key| @storage.delete(key) }
    notify_observers(:after_sign_out)
    self.forget!
  end

  def touch!
    @storage[:expires_at] = Brooklyn::Application.config.session.timeout_in.from_now
  end

  def forget!
    @storage.delete(:expires_at)
  end

  def expires_at
    self.touch! if @storage[:expires_at].nil?
    @storage[:expires_at]
  end

  def expired?
    expires_at <= Time.now
  end
end
