require './acceptance/spec_helper'

# all tests require js: true in order to be sure that we are finding (or not finding) the cancel modal button
# as per the order state.
feature "Cancel order as admin", js: true do
  include_context 'order admin'

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    cancel_order(order)
    order_should_not_be_cancellable
  end

  scenario "for a confirmed order" do
    order = given_order(:confirmed)
    visit admin_order_path(order.id)
    cancel_order(order)
    order_should_not_be_cancellable
  end

  scenario "for a shipped order" do
    order = given_order(:shipped)
    visit admin_order_path(order.id)
    cancel_order(order)
    order_should_not_be_cancellable
  end

  scenario "for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    cancel_order(order)
    order_should_not_be_cancellable
  end

  scenario "should not be possible for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    order_should_not_be_cancellable
  end

  scenario "should not be possible for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    order_should_not_be_cancellable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    order_should_not_be_cancellable
  end
end
