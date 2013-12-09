require 'balanced'

class Purchase < ModelBase
  include ActiveSupport::Benchmarkable

  class CardRejected < Exception; end
  class CardNotValidated < Exception; end

  attr_accessor :cardholder_name, :card_number, :expires_on, :security_code, :line1, :line2, :city, :state, :zip,
                :phone, :bill_to_shipping
  attr_date :expires_on

  validates :cardholder_name, presence: true, length: {maximum: 80, allow_blank: true}
  validates :card_number, presence: true, credit_card: {allow_blank: true}
  validates :expires_on, presence: true, date: {allow_blank: true, after_or_equal_to: Date.today.at_beginning_of_month }
  validates :security_code, presence: true, format: {with: %r/\A\d{3,4}\z/, allow_blank: true}
  validates :line1, :presence => true, length: {maximum: 80, allow_blank: true}
  validates :line2, length: {maximum: 80, allow_blank: true}
  validates :city, :presence => true, length: {maximum: 80, allow_blank: true}
  validates :state, :presence => true, :subregion => {:country => :US, :allow_blank => true}
  validates :zip, :presence => true, length: {maximum: 80, allow_blank: true},
            :postal_code => {:country => :us, :allow_blank => true}
  validates :phone, :presence => true, length: {maximum: 80, allow_blank: true},
            :phone => {:country => :us, :allow_blank => true}

  normalize_attributes :card_number, with: :credit_card

  # Creates and returns a Balanced card based on the purchase information.
  #
  # @return [Balanced::Card] the newly-created card
  # @raise [Purchase::CardRejected] if the card could not be tokenized
  # @raise [Purchase::CardNotValidated] if the card could not be validated
  # @raise [Balanced::Error] if the card could not be created for some other reason
  # @see https://www.balancedpayments.com/docs/api/#cards
  def create_card!
    benchmark "Create Balanced card" do
      Balanced::Card.new(to_card_params).save
    end
  rescue Balanced::PaymentRequired => e
    logger.warn("Balanced card rejected: #{e.message}")
    raise CardRejected.new(e.message)
  rescue Balanced::Conflict => e
    raise unless e.category_code == 'card-not-validated'
    raise CardNotValidated.new(e.message)
  end

  def bill_to_shipping_address(shipping)
    [:line1, :line2, :city, :state, :zip, :phone].each { |attr| self.send("#{attr}=".to_sym, shipping.send(attr)) }
    self.bill_to_shipping = true
  end

  def to_card_params
    {
      name: cardholder_name,
      card_number: card_number,
      expiration_month: expires_on.strftime("%m"),
      expiration_year: expires_on.strftime("%Y"),
      security_code: security_code
    }
  end

  def to_billing_address_attrs
    {
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      zip: zip,
      phone: phone
    }
  end
end
