require './acceptance/spec_helper'

feature "Settle order as admin" do
  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    settle_order
    order_should_not_be_settleable
  end

  scenario "should not be possible for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  scenario "should not be possible for a confirmed order" do
    order = given_order(:confirmed)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  scenario "should not be possible for a shipped order" do
    order = given_order(:shipped)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  scenario "should not be possible for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  scenario "should not be possible for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    order_should_not_be_settleable
  end

  def settle_order
    settle_button.click
  end

  def order_should_not_be_settleable
    settle_button.should be_nil
  end

  def settle_button
    find('[data-action=settle]')
  rescue Capybara::ElementNotFound
    nil
  end
end
