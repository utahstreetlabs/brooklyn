require 'attribute_normalizer'

# a base class for non-AR models
class ModelBase
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include AttributeNormalizer

  def initialize(attrs = {})
    attrs = fixup_multiparameter_date_attributes(attrs)
    attrs.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def fixup_multiparameter_date_attributes(attrs)
    self.class.date_attributes.inject(attrs) { |m, date_attr| fixup_multiparameter_date_attribute(m, date_attr) }
  end

  # thanks http://stackoverflow.com/questions/4711948/multiparameter-error-with-datetime-select
  def fixup_multiparameter_date_attribute(attrs, date_attr)
    keys = []
    values = []
    attrs.each_key {|k| keys << k if k =~ /#{date_attr}/ }.sort
    keys.each do |key|
      values << attrs[key]; attrs.delete(key)
    end
    attrs[date_attr] = Date.parse(values.join("-")) if values.any?
    attrs
  end

  def logger
    self.class.logger
  end

  def self.date_attributes
    @date_attributes ||= []
  end

  def self.attr_date(name)
    date_attributes << name.to_sym
  end

  def self.logger
    Rails.logger
  end
end
