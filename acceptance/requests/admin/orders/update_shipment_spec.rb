require './acceptance/spec_helper'

feature "Update shipment as admin" do
  include_context 'order admin'

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  let(:old_tracking_number) { '1Z9999999999999999' }
  let(:new_tracking_number) { '1Z12345E0205271688' }

  context "for a shipped order", js: true do
    let!(:order) do
      o = given_order(:shipped)
      o.shipment.update_attributes!(tracking_number: old_tracking_number)
      o
    end

    scenario "happily" do
      visit admin_order_path(order.id)
      update_shipment(new_tracking_number)
      shipment_should_be_updated(new_tracking_number)
    end

    context "with normally bogus tracking number" do
      let(:bogus_tracking_number) { '12345678901234567890' }

      before { visit admin_order_path(order.id) }

      scenario "with tracking validation" do
        update_shipment(bogus_tracking_number)
        shipment_should_not_be_updated(old_tracking_number)
      end

      scenario "without tracking validation" do
        update_shipment(bogus_tracking_number, disable_tracking_validation: true)
        shipment_should_be_updated(order.shipment.normalize_tracking_number(bogus_tracking_number))
        user_should_have_tracking_update_notification(order.buyer)
        user_should_have_tracking_update_notification(order.listing.seller)
      end
    end
  end

  scenario "should not be possible for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  scenario "should not be possible for a confirmed order" do
    order = given_order(:confirmed)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  scenario "should not be possible for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  scenario "should not be possible for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  scenario "should not be possible for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    shipment_should_not_be_updatable
  end

  def user_should_have_tracking_update_notification(user)
    logout
    login_as user.email
    visit notifications_path
    page.should have_css('[data-role=notification][data-type=tracking_number_updated]')
  end
end
