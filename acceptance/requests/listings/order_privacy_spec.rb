require './acceptance/spec_helper'

feature "Manage order privacy from listing" do
  if feature_enabled?(:feedback)
    background do
      login_as "starbuck@galactica.mil"
    end

    scenario "make private order public", js: true do
      order = given_order(:complete, buyer: current_user, private: true)
      order = FactoryGirl.create(:complete_order, buyer: current_user, :private => true)
      visit listing_path(order.listing)
      make_order_public
      order_should_be_public
    end

    scenario "make public order private", js: true do
      order = given_order(:complete, buyer: current_user, private: false)
      visit listing_path(order.listing)
      make_order_private
      order_should_be_private
    end
  end

  def make_order_public
    public_button.click
    wait_for_dom_to_update
  end

  def make_order_private
    private_button.click
    wait_for_dom_to_update
  end

  def order_should_be_public
    public_button.should be_active
    private_button.should_not be_active
  end

  def order_should_be_private
    public_button.should_not be_active
    private_button.should be_active
  end

  def public_button
    find('[data-action=public]')
  rescue Capybara::ElementNotFound
    nil
  end

  def private_button
    find('[data-action=private]')
  rescue Capybara::ElementNotFound
    nil
  end

  matcher :be_active do
    match do |button|
      button[:class] =~ /active/
    end
  end
end
