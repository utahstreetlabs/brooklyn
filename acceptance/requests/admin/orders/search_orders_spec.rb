require './acceptance/spec_helper'

feature "Search orders as admin" do
  let(:order1) { given_order(:confirmed) }
  let(:order2) { given_order(:confirmed) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "finds order by ref num" do
    visit admin_orders_path
    search_datagrid order1.reference_number
    page.should have_content(order1.reference_number)
    page.should_not have_content(order2.reference_number)
  end
end
