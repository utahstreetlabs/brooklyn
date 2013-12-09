module Users
  module PriceAlerts
    extend ActiveSupport::Concern

    included do
      has_many :price_alerts, dependent: :destroy
    end

    def price_alert_for(listing)
      price_alerts.where(listing_id: listing.id).first
    end

    def build_price_alert(listing, attrs = {})
      price_alerts.build(attrs.reverse_merge(threshold: PriceAlert::Discounts::ANY).merge(listing: listing))
    end

    def save_price_alert!(listing, attrs = {})
      logger.debug("Saving price alert for listing #{listing.id} with attributes #{attrs}")
      price_alerts.create!(attrs.merge(listing: listing))
    rescue ActiveRecord::RecordNotUnique
      alert = price_alert_for(listing) or
        raise ActiveRecord::RecordNotFound
      alert.update_attributes!(attrs)
      alert
    end

    def delete_price_alert(listing)
      price_alerts.where(listing_id: listing.id).destroy_all
    end
  end
end
