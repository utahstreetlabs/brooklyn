require './acceptance/spec_helper'
require 'timecop'

feature "Examine bought items on dashboard" do
  include_context 'with facebook test user'

  # given_registered_user doesn't work here, I think because of the oauth stuff
  let(:user) { FactoryGirl.create(:registered_user, balanced_url: nil) }

  context "Auto-login when visiting dashboard", js: true do
    # This simulates a Facebook user that is specifically connected to
    # our app with a given login, but is logged out.  The result is
    # that the user is connected to Facebook and has authorized our app.
    background do
      visit root_path
      fb_user_login
      login_as user.email
      visit dashboard_path
      connect_to 'Facebook'
      connection_should_succeed 'Facebook'
      visit logout_path
      expect(page).to have_content("Log In")
    end

    scenario 'succeeds when visiting dashboard' do
      # On first visit, we should get redirected because we're unauthorized.
      visit bought_dashboard_path
      page_should_be_dashboard_bought
    end

    scenario 'does not happen when not logged in to Facebook', js: true do
      pending 'looks like we may be getting bitten by transient facebook issues with logging out'
      fb_logout_test_user
      visit bought_dashboard_path
      page_should_not_have_logging_in_modal
      expect(page).to have_content("Signup with Facebook")
    end

    def page_should_be_dashboard_bought
      retry_expectations { expect(current_path).to eq(bought_dashboard_path) }
    end
  end
end

feature "Complete an order" do
  let!(:order) { given_order(:delivered) }

  scenario "complete order from dashboard", js: true do
    login_as order.buyer.email
    visit bought_dashboard_path
    expect(page).to have_content('Delivered')
    click_on 'Complete'
    wait_a_while_for do
      expect(page).to have_content('Successful purchase!')
    end
  end
end

feature "Manage shipped but not delivered order", js: true do
  let(:order) { given_order(:shipped) }

  scenario "by tracking it" do
    after_delivery_confirmation_period_elapsed do
      login_as order.buyer.email
      visit bought_dashboard_path
      within_update_delivery_modal do
        track_order
      end
      retry_expectations do
        expect(tracking_window).to be_on_tracking_page
      end
      close_tracking_window
    end
  end

  scenario "by confirming delivery" do
    after_delivery_confirmation_period_elapsed do
      login_as order.buyer.email
      visit bought_dashboard_path
      open_update_delivery_modal do
        confirm_delivery
      end
      expect(order_status).to be_delivered
    end
  end

  scenario "by reporting non-delivery" do
    after_delivery_confirmation_period_elapsed do
      login_as order.buyer.email
      visit bought_dashboard_path
      open_update_delivery_modal do
        report_non_delivery
      end
      expect(order_status).to be_shipped
    end
  end

  def after_delivery_confirmation_period_elapsed(&block)
    Timecop.travel(order.shipped_at + Order.delivery_confirmation_period_duration + 1.day, &block)
  end

  def within_update_delivery_modal(&block)
    open_update_delivery_modal(&block)
    close_modal(update_delivery_modal_id)
  end

  def open_update_delivery_modal(&block)
    open_modal(update_delivery_modal_id, &block)
  end

  def track_order
    find('[data-action=track]').click
  end

  def confirm_delivery
    find('[data-action=confirm-delivery]').click
  end

  def report_non_delivery
    find('[data-action=report-non-delivery]').click
  end

  def update_delivery_modal_id
    "update-delivery-#{order.id}"
  end

  def delivery_confirmed_modal_id
    "delivery-confirmed-#{order.id}"
  end

  def delivery_not_confirmed_modal_id
    "delivery-not-confirmed-#{order.id}"
  end

  def tracking_window
    '_tracking'
  end

  def close_tracking_window
    page.within_window(tracking_window) do
      page.execute_script('window.close();')
    end
  end

  def order_status
    find('[data-role=status]')
  end

  matcher :be_on_tracking_page do
    match do |window|
      page.within_window(window) do
        current_url =~ /ups\.com/
      end
    end
  end

  matcher :be_shipped do
    match do |element|
      element.has_content?('Shipped')
    end
  end

  matcher :be_delivered do
    match do |element|
      element.has_content?('Delivered')
    end
  end
end
