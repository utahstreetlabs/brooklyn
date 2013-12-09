module TabsHelpers
  def remote_tab_header(id)
    find(".remote-tabs-headers ##{id}")
  rescue Capybara::ElementNotFound
    nil
  end

  def show_remote_tab(id)
    remote_tab_header(id).find('a').click
  end

  def remote_tab_pane(id)
    find(".remote-tabs-panes ##{id}")
  rescue Capybara::ElementNotFound
    nil
  end

  def within_remote_tab_pane(id, &block)
    within remote_tab_pane(id) do
      yield
    end
  end
end

RSpec.configure do |config|
  config.include TabsHelpers
end
