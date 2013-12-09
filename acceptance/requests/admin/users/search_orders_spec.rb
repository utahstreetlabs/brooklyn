require './acceptance/spec_helper'

feature "Search users as admin" do
  let!(:user1) { FactoryGirl.create(:registered_user) }
  let!(:order1) { given_order(:shipped, buyer: user1) }
  let!(:order2) { given_order(:shipped, buyer: user1) }
  let!(:order3) { given_order(:shipped, buyer: user1) }

  background do
    given_global_interest
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "finds all orders for user" do
    visit admin_user_path(user1.id)
    click_user_orders
    expect(page).to have_content(order1.reference_number)
    expect(page).to have_content(order2.reference_number)
    expect(page).to have_content(order3.reference_number)
  end

  scenario "can view individual order for user" do
    visit admin_user_path(user1.id)
    click_user_orders
    expect(page).to have_content(order1.reference_number)
    click_user_order(order1.id)
    expect(page).to have_css("title:contains('Order #{order1.reference_number}')")
  end

  private

  def click_user_orders
    find('[data-role=user-orders] a').click
  end

  def click_user_order(order_id)
    find("[data-role=user-order-#{order_id}] a").click
  end
end
