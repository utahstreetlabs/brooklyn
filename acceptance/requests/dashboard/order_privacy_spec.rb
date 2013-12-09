require './acceptance/spec_helper'

feature "Manage order privacy from dashboard" do
  if feature_enabled?(:feedback)
    background do
      login_as "starbuck@galactica.mil"
    end

    scenario "make private order public", js: true do
      given_order(:delivered, buyer: current_user, private: true)
      visit bought_dashboard_path
      make_order_public(order)
      order_should_be_public(order)
    end

    scenario "make public order private", js: true do
      given_order(:complete, buyer: current_user, private: false)
      visit bought_dashboard_path
      make_order_private(order)
      order_should_be_private(order)
    end
  end

  def make_order_public(order)
    within_order_privacy(order) do
      public_button.click
      wait_for_dom_to_update
    end
  end

  def make_order_private(order)
    within_order_privacy(order) do
      private_button.click
      wait_for_dom_to_update
    end
  end

  def order_should_be_public(order)
    within_order_privacy(order) do
      public_button.should be_active
      private_button.should_not be_active
    end
  end

  def order_should_be_private(order)
    within_order_privacy(order) do
      public_button.should_not be_active
      private_button.should be_active
    end
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
