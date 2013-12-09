require './acceptance/spec_helper'

feature "Track order as admin" do
  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  context "for a confirmed order" do
    let!(:order) { given_order(:confirmed) }

    context "with prepaid shipping" do
      let!(:shipping_option) { FactoryGirl.create(:shipping_option, listing: order.listing) }

      context "and a shipping label" do
        let!(:shipping_label) { FactoryGirl.create(:shipping_label, order: order) }

        context "that is active" do
          scenario 'happily' do
            visit admin_order_path(order.id)
            order_should_be_trackable
            track_order
          end
        end

        context "that has expired" do
          before { shipping_label.expire! }

          scenario "should not be possible" do
            visit admin_order_path(order.id)
            order_should_not_be_trackable
          end
        end
      end

      context "but no shipping label" do
        scenario "should not be possible" do
          visit admin_order_path(order.id)
          order_should_not_be_trackable
        end
      end
    end

    context "with basic shipping" do
      scenario "should not be possible" do
        visit admin_order_path(order.id)
        order_should_not_be_trackable
      end
    end
  end

  scenario "for a shipped order" do
    order = given_order(:shipped)
    visit admin_order_path(order.id)
    order_should_be_trackable
    track_order
  end

  scenario "for a delivered order" do
    order = given_order(:delivered)
    visit admin_order_path(order.id)
    order_should_be_trackable
    track_order
  end

  scenario "for a complete order" do
    order = given_order(:complete)
    visit admin_order_path(order.id)
    order_should_be_trackable
    track_order
  end

  scenario "for a settled order" do
    order = given_order(:settled)
    visit admin_order_path(order.id)
    order_should_be_trackable
    track_order
  end

  scenario "should not be possible for a pending order" do
    order = given_order(:pending)
    visit admin_order_path(order.id)
    order_should_not_be_trackable
  end

  scenario "should not be possible for a cancelled order" do
    order = given_order(:cancelled)
    visit admin_order_path(order.id)
    order_should_not_be_trackable
  end

  def track_order(options = {})
    track_button.click
  end

  def order_should_be_trackable
    track_button.should be
  end

  def order_should_not_be_trackable
    track_button.should be_nil
  end

  def track_button
    find("[data-action=track]")
  rescue Capybara::ElementNotFound
    nil
  end
end
