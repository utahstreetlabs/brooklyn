module TagHelpers
  def check_tag(name)
    tag = Tag.find_by_name!(name)
    check("id_#{tag.id}")
  end

  def click_on_merge(name)
    within_tag(name) do
      find("[data-action=merge]").click
    end
  end

  def click_on_delete(name)
    within_tag(name) do
      find("[data-action=delete]").click
    end
  end

  def within_tag(name, &block)
    tag = Tag.find_by_name!(name)
    within("[data-tag='#{tag.id}']", &block)
  end

  RSpec::Matchers.define :have_tag do |name|
    match do |page|
      page.has_css?(".tag .tag-name:contains('#{name}')")
    end
  end

  RSpec::Matchers.define :have_tags do |count|
    match do |page|
      page.all('.tag').size == count
    end
    failure_message_for_should do |actual|
      "expected #{count} tags, not #{actual}"
    end
  end
end

RSpec.configure do |config|
  config.include TagHelpers
end
