# A validator for US Social Security Numbers. Validates basic format only, not that the sections of the number make
# sense according to the SSN assignment process or that the number has actually been assigned by the Social Security
# Administration.
#
# XXX: add to activevalidators
#
# @see http://en.wikipedia.org/wiki/Social_Security_number
class SsnValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute) if value.present? && !valid_ssn?(value)
  end

  REGEXES = [
    /\A\d{3}\-\d{2}\-\d{4}\z/,
    /\A\d{9}\z/
  ]

  # A Social Security Number is 9 digits. That's it!
  def valid_ssn?(value)
    REGEXES.detect { |fmt| value.match(fmt) }
  end
end
