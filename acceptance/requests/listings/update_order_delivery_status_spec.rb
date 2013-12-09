require './acceptance/spec_helper'

feature "Update an order's delivery status" do
  let!(:order) { given_order(:shipped) }

  scenario "by confirming delivery" do
    login_as order.buyer.email
    visit listing_path(order.listing)
    confirm_delivery
    order_status.should be_delivered
  end

  scenario "by reporting non-delivery" do
    login_as order.buyer.email
    visit listing_path(order.listing)
    report_non_delivery
    order_status.should be_shipped
    page.should have_not_delivered_message
  end

  def confirm_delivery
    find('[data-action=confirm-delivery]').click
  end

  def report_non_delivery
    find('[data-action=report-non-delivery]').click
  end

  def order_status
    order.reload
    order.status.to_sym
  end

  matcher :be_delivered do
    match do |status|
      status.should == :delivered
    end
  end

  matcher :be_shipped do
    match do |status|
      status.should == :shipped
    end
  end

  matcher :have_not_delivered_message do
    match do |page|
      page.should have_flash_message(:notice, 'listings.not_delivered',
                                     support_link: Brooklyn::Application.config.email.to.help)
    end
  end
end
