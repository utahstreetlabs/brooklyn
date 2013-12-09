require 'ladon/model'

class PriceAlerter
  def new_message(attributes = {})
    if attributes.key?(:slug)
      IndividualMessage.new(attributes)
    else
      MassMessage.new(attributes)
    end
  end

  def send_message!(message)
    message.enqueue!
  end

  class PriceAlertMessage < Ladon::Model
  end

  class IndividualMessage < Ladon::Model
    attr_accessor :slug, :query
    validates :slug, presence: true
    validates :query, presence: true

    def user
      unless instance_variable_defined?(:@user)
        @user = User.where(slug: slug).first
      end
      @user
    end

    def enqueue!
      raise ActiveRecord::RecordNotFound unless user
      profile = user.for_network(Network::Facebook)
      raise Network::NotConnected.new(Network::Facebook) unless profile
      Facebook::NotificationPriceAlertPostJob.enqueue(profile.id)
    end
  end

  class MassMessage < Ladon::Model
    attr_accessor :count
    validates :count, presence: true, numericality: {integer_only: true, greater_than: 0, allow_blank: true}

    def enqueue!
      Facebook::NotificationPriceAlertJob.enqueue(count)
    end
  end
end
