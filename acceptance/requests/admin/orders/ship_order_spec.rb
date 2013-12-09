require './acceptance/spec_helper'

feature "Ship order as admin" do
  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  context "for a confirmed order" do
    let!(:order) { given_order(:confirmed) }

    scenario "happily", js: true do
      visit admin_order_path(order.id)
      ship_order tracking_number: '1Z12345E0205271688'
      order_should_not_be_shippable
    end

    scenario "with invalid input", js: true do
      visit admin_order_path(order.id)
      ship_order
      modal_should_have_tracking_number_error
      order_should_be_shippable
    end
  end

  scenario "should not be possible for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  scenario "should not be possible for a shipped order" do
    order = given_order(:shipped)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  scenario "should not be possible for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  scenario "should not be possible for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  scenario "should not be possible for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    order_should_not_be_shippable
  end

  def ship_order(options = {})
    open_modal(modal_id)
    within_modal(modal_id) do
      fill_in 'shipment_tracking_number', with: options[:tracking_number]
    end
    save_modal(modal_id)
    wait_for(2)
  end

  def order_should_be_shippable
    ship_button.should be
  end

  def order_should_not_be_shippable
    ship_button.should be_nil
  end

  def modal_should_have_tracking_number_error
    within_modal(modal_id) do
      page.should have_content('is required')
    end
  end

  def ship_button
    find("[data-target='#ship-modal']")
  rescue Capybara::ElementNotFound
    nil
  end

  def modal_id
    :ship
  end
end
