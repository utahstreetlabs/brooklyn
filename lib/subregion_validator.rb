require 'carmen'

# A validator for Carmen subregions.
#
# XXX: add to activevalidators
#
# @see https://github.com/jim/carmen
class SubregionValidator < ActiveModel::EachValidator
  attr_reader :country, :subregions

  def initialize(options)
    @country = Carmen::Country.coded(options[:country].to_s)
    @subregions = @country.subregions.map(&:code) if @country
    super
  end

  def validate_each(record, attribute, value)
    record.errors.add(attribute) if value.present? && !valid_subregion?(value)
  end

  def valid_subregion?(value)
    subregions.include?(value.to_s)
  end

  def check_validity!
    raise ArgumentError.new("No such country #{options[:country]}") unless country
  end
end
