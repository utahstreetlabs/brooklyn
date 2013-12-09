require 'carmen'

module Balanced
  class PersonMerchantIdentity < ::ModelBase
    attr_accessor :user, :name, :street_address, :postal_code, :born_on, :phone_number, :tax_id, :region
    attr_date :born_on

    # keeps track of the number of times the user has tried to verify their identity
    attr_reader :attempt

    validates :name, presence: true
    validates :street_address, presence: true
    validates :postal_code, presence: true, postal_code: {country: :us, allow_blank: true}
    validates :born_on, presence: true, date: {before: Date.tomorrow, allow_blank: true}
    validates :phone_number, presence: true, phone: {allow_blank: true}
    validates :tax_id, presence: true, ssn: true, if: -> { attempt > 2 }
    # region is not needed for anything, but we can simulate a "more information required" error by passing region
    # "EX" and postal code "99999". see https://www.balancedpayments.com/docs/merchant#testing.

    # tried to use `normalize_attributes :attempt, with: :integer`, but it wsan't working for an unknown reason
    def attempt=(value)
      @attempt = value.to_i
    end

    USA = Carmen::Country.coded('US')
    def to_merchant_params
      hash = {
        type: 'person',
        name: name,
        street_address: street_address,
        postal_code: postal_code,
        country: USA.alpha_3_code,
        phone_number: phone_number
      }
      hash[:dob] = born_on.strftime("%Y-%m-%d") if born_on.present?
      hash[:tax_id] = tax_id if tax_id.present?
      hash[:region] = region if region.present?
      hash
    end
  end
end
