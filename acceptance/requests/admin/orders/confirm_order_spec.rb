require './acceptance/spec_helper'

feature "Confirm order as admin" do
  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "for a confirmed order" do
    order = given_order(:confirmed)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a shipped order" do
    order = given_order(:shipped)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    order_should_not_be_confirmable
  end

  def confirm_order
    confirm_button.click
  end

  def order_should_not_be_confirmable
    confirm_button.should be_nil
  end

  def confirm_button
    find('[data-action=confirm]')
  rescue Capybara::ElementNotFound
    nil
  end
end
