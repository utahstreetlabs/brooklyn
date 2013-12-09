require 'ladon'

module Shipments
  # Expires all shipping labels that need to be expired.
  #
  class ExpireShippingLabelsJob < Ladon::Job
    @queue = :shipments

    # @option options [ActiveSupport::TimeWithZone] :before (+Time.zone.now+) any unexpired label that is scheduled to
    #   expire before this time will be matched
    # @return [ActiveRecord::Relation]
    def self.work(options = {})
      ShippingLabel.find_to_expire(options).find_each do |label|
        with_error_handling("Expire shipping label", shipping_label: label.id) do
          label.expire!
        end
      end
    end
  end
end
