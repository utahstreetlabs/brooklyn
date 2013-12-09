require './acceptance/spec_helper'

feature "Create registered user" do
  background do
    login_as 'roslin@galactica.mil', superuser: true
    visit new_admin_user_path
  end

  let(:firstname) { 'John' }
  let(:lastname)  { 'Cavil' }
  let(:email)     { 'numberone@cylon.mil' }
  let(:password)  { 'Br0th3rC@v!l' }

  scenario 'succeeds' do
    submit_new_user_form
    should_be_on_user_details_page
  end

  scenario 'shows an error when input is not valid' do
    submit_new_user_form(password_confirmation: '')
    should_be_on_new_user_page_with_error('The passwords you entered did not match')
  end

  def submit_new_user_form(params = {})
    fill_in 'First name',       with: params.fetch(:firstname,             firstname)
    fill_in 'Last name',        with: params.fetch(:lastname,              lastname)
    fill_in 'Email',            with: params.fetch(:email,                 email)
    fill_in 'Password',         with: params.fetch(:password,              password)
    fill_in 'Confirm password', with: params.fetch(:password_confirmation, password)
    click_on 'Save changes'
  end

  def should_be_on_user_details_page
    user = User.find_by_email(email)
    current_path.should == admin_user_path(user.id)
  end

  def should_be_on_new_user_page_with_error(error)
    current_path.should == admin_users_path
    page.should have_content(error)
  end
end
