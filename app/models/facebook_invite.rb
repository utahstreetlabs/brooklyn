require 'ladon/model'

# A UI-level model that encapsulates the information needed to send invites via Facebook direct share.
class FacebookInvite < Ladon::Model
  def self.max_recipients
    Brooklyn::Application.config.invites.facebook.max_recipients
  end

  attr_accessor :id, :message
  validates :id, presence: true, length: {maximum: max_recipients}

  alias_method :ids, :id
end
