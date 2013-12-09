require 'ladon/model'
require 'mail'

# A UI-level model that encapsulates the information needed to send invites via email.
class EmailInvite < Ladon::Model
  attr_reader :to, :addresses
  attr_accessor :message

  validates :to, presence: true

  # activemodel-validators doesn't support lists of email addresses, and anyway, we want to add errors to a different
  # attribute than the one whose value is being validated. if somebody wants to package this up for that library, go
  # for it.
  validates_each :addresses do |record, attribute, value|
    invalid = []
    value.each do |addr|
      begin
        address = Mail::Address.new(addr)
        valid = address.domain && value.include?(address.address)
      rescue Mail::Field::ParseError
        valid = false
      end
      invalid << addr unless valid
    end
    record.errors.add(:to, :invalid, addresses: invalid.join(', ')) if invalid.any?
  end

  validates_each :addresses do |record, attribute, value|
    record.errors.add(:to, :too_many, count: max_recipients) if value.size > max_recipients
  end

  def initialize(*args)
    @addresses = []
    super
  end

  def to=(value)
    @to = value
    @addresses.concat(to.split(/[\s,]+/)) if to.present?
  end

  def self.max_recipients
    Brooklyn::Application.config.invites.email.max_recipients
  end
end
