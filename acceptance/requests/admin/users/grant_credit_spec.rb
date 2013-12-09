require './acceptance/spec_helper'

feature "Grant credits", %q{
  In order to encourage and reward awesome users
  As an admin
  I want to be able to grant credits to users
} do

  let!(:user) { given_registered_user email: "billy@galactica.gov" }

  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  # if this spec fails in ci with this error:
  #  Selenium::WebDriver::Error::MoveTargetOutOfBoundsError:
  #    Element cannot be scrolled into view:javascript:void(0)
  # then pend it, because it's probably the issue I have in dev where the browser window is too narrow and the
  # button is off screen. see http://code.google.com/p/selenium/issues/detail?id=3075 for more info. (bcm)
  scenario 'happily', js: true do
    visit admin_user_path(user.id)
    user_should_have_credit_balance '$0.00'
    grant_credit '10.00'
    wait_for(2)
    user_should_have_credit_balance '$10.00'
  end

  scenario 'with invalid input', js: true do
    visit admin_user_path(user.id)
    user_should_have_credit_balance '$0.00'
    grant_credit '0.00'
    modal_should_have_balance_error
    user_should_have_credit_balance '$0.00'
  end

  def user_should_have_credit_balance(balance)
    find('[data-role=credit-balance]').text.strip.should == balance
  end

  def grant_credit(amount)
    open_modal(modal_id)
    within_modal(modal_id) do
      fill_in 'credit_amount', with: amount
    end
    save_modal(modal_id)
  end

  def modal_should_have_balance_error
    within_modal(modal_id) do
      page.should have_content('must be greater than 0')
    end
  end

  def modal_id
    :grant_credit
  end
end
