require 'timecop'
require './acceptance/spec_helper'

feature "Review orders with expired handling as admin" do
  let!(:order) { given_order(:confirmed }

  scenario "finds order by ref num" do
    Timecop.travel(order.handling_expires + 5.minutes)
    login_as('starbuck@galactica.mil', admin: true)
    visit handling_expired_admin_orders_path
    page.should have_content(order.reference_number)
  end
end
