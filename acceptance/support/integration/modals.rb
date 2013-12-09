module ModalsHelpers
  def open_modal(id, options = {}, &block)
    find("[data-target='##{id}-modal']", options).click
    within_modal(id, &block) if block_given?
  end

  def within_modal(id, &block)
    within("##{id}-modal", &block)
  end

  def save_modal(id)
    within_modal(id) { find('[data-save=modal]').click }
  end

  def close_modal(id)
    within_modal(id) { find('a[data-dismiss=modal]').click }
  end

  def modal_should_be_hidden(id)
    page.should have_css("##{id}-modal", visible: false)
  end

  def modal_should_be_visible(id)
    page.should have_css("##{id}-modal", visible: true)
  end

  def modal_should_not_exist(id)
    page.should_not have_css("##{id}-modal")
  end
end

RSpec.configure do |config|
  config.include ModalsHelpers
end
