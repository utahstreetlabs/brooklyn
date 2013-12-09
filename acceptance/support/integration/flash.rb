# encoding: utf-8
require 'nokogiri'

RSpec::Matchers.define :have_flash_message do |level, key, options = {}|
  match do |page|
    key = "controllers.#{key}" unless key =~ /^controllers/
    flash_container(level).has_content?(msg(key, options))
  end

  failure_message_for_should do |actual|
    "expected flash #{level} message '#{flash_container(level).text}' to be '#{msg(key, options)}'"
  end

  def flash_container(level)
    find("[data-role=flash-#{level}]")
  end

  def msg(key, options)
    # strip html from the translated string
    Nokogiri::HTML(I18n.translate(key, options)).inner_text
  end
end
