require 'active_support/hash_with_indifferent_access'
require 'active_support/json'
require 'i18n'

class TopMessage
  include ActionView::Helpers::UrlHelper

  @@attrs = [:key, :text, :header]
  attr_reader *@@attrs

  def initialize(key, params = {})
    @key = key
    if params.key?(:links)
      Hash[params.delete(:links)].each do |type, url_helper|
        params["#{type}_link".to_sym] = link_to(t("#{type}_link_text"), url_helpers.send(url_helper))
      end
    end
    @header = params.delete(:header) || t(:header, params.merge(default: ''))
    @text = params.delete(:text) || t(:text, params)
  end

  def to_s
    ActiveSupport::JSON.encode(header: header, text: text)
  end

  def ==(other)
    @@attrs.inject(true) {|m, v| m && (self.send(v) == other.send(v))}
  end

  def t(tkey, params = {})
    I18n.t(tkey, params.reverse_merge(scope: i18n_scope))
  end

  def i18n_scope
    [:top_message, key]
  end

  def logger
    Rails.logger
  end

  def url_helpers
    Brooklyn::Application.routes.url_helpers
  end

  def self.decode(key, str)
    new(key, HashWithIndifferentAccess.new(ActiveSupport::JSON.decode(str)))
  end
end
