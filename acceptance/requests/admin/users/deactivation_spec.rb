require './acceptance/spec_helper'

feature "Deactivate", %q{
  In order to make users comfortable with the site
  As an admin
  I want to be able to deactivate accounts
} do

  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  let!(:user) { given_registered_user email: "billy@galactica.gov" }
  let!(:listing) { given_listing seller: user.email }

  scenario 'happily' do
    visit admin_user_path(user.id)
    deactivate_user
    user_should_be_deactivated
    visit browse_for_sale_path
    catalog_should_be_empty
  end

  scenario 'should not be possible for users with pending orders' do
    given_order(:pending, listing: listing)
    visit admin_user_path(user.id)
    user_should_not_be_deactivateable
  end

  def deactivate_user
    deactivate_button.click
  end

  def user_should_be_deactivated
    find('[data-role=registration-state]').text.strip.should == 'Inactive'
  end

  def catalog_should_be_empty
    page.should have(0).product_cards
  end

  def user_should_not_be_deactivateable
    deactivate_button.should be_nil
  end

  def deactivate_button
    find('[data-action=deactivate]')
  rescue Capybara::ElementNotFound
    nil
  end
end
