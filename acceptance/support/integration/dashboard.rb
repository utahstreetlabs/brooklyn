module DashboardHelpers
  shared_context 'viewing my dashboard' do
    before do
      login_as "starbuck@galactica.mil"
      visit dashboard_path
    end
  end

  def within_order_privacy(order, &block)
    within "[data-order='#{order.id}'][data-role=buyer-privacy]", &block
  end
end

RSpec.configure do |config|
  config.include DashboardHelpers
end

module SidebarSelectors
  def follow_suggestions
    all ".follow-suggestion"
  end

  def invite_suggestions
    all ".invite-suggestion"
  end
end

class Capybara::Session
  include SidebarSelectors
end

class Capybara::Node::Element
  include SidebarSelectors
end

