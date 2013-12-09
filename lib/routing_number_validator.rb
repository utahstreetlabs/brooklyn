# A validator for US routing transit numbers. Ripped off from ActiveMerchant::Billing::Check - thanks guys!
#
# XXX: add to activevalidators
#
# @see http://en.wikipedia.org/wiki/Routing_transit_number#Internal_checksums
class RoutingNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute) if value.present? && !valid_routing_number?(value)
  end

  def valid_routing_number?(routing_number)
    return false unless routing_number.to_s =~ /\A(\d{9})\z/
    d = $1.split('').map(&:to_i)
    checksum = ((3 * (d[0] + d[3] + d[6])) +
                (7 * (d[1] + d[4] + d[7])) +
                     (d[2] + d[5] + d[8])) % 10
    checksum == 0
  end
end
