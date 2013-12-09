require './acceptance/spec_helper'

feature "Edit user" do
  let(:user) { FactoryGirl.create(:registered_user) }

  background do
    v = login_as 'roslin@galactica.mil', superuser: true
    visit edit_admin_user_path(user.id)
  end

  let(:firstname) { 'John' }
  let(:lastname)  { 'Cavil' }
  let(:fullname)  { "#{firstname} #{lastname}"}
  let(:slug)      { fullname.parameterize }

  scenario 'succeeds' do
    submit_edit_user_form
    should_be_on_user_details_page(user)
    user_should_be_updated(user)
  end

  scenario 'shows an error when input is not valid' do
    submit_edit_user_form(firstname: '')
    should_be_on_edit_user_page_with_error(user, 'You must enter your first name')
  end

  scenario 'sets undetermined listing access' do
    update_listing_access(:undetermined)
    user_should_have_listing_access(:undetermined)
  end

  scenario 'sets full listing access' do
    update_listing_access(:full)
    user_should_have_listing_access(:full)
  end

  scenario 'sets limited listing access' do
    update_listing_access(:limited)
    user_should_have_listing_access(:limited)
  end

  scenario 'sets no listing access' do
    update_listing_access(:none)
    user_should_have_listing_access(:none)
  end

  def submit_edit_user_form(params = {})
    fill_in 'First name', with: params.fetch(:firstname, firstname)
    fill_in 'Last name',  with: params.fetch(:lastname,  lastname)
    fill_in 'Full name',  with: params.fetch(:fullname,  fullname)
    fill_in 'Slug',       with: params.fetch(:slug,      slug)
    choose 'Enabled'
    click_on 'Save changes'
  end

  def should_be_on_user_details_page(user)
    current_path.should == admin_user_path(user.id)
  end

  def user_should_be_updated(user)
    user.reload
    user.firstname.should == firstname
    user.lastname.should  == lastname
    user.name.should      == fullname
    user.slug.should      == slug
    user.web_site_enabled?.should    be_true
  end

  def should_be_on_edit_user_page_with_error(user, error)
    current_path.should == admin_user_path(user.id)
    page.should have_content(error)
  end

  def update_listing_access(level)
    id = case level
    when :undetermined then nil
    when :full then User::ListingAccess::FULL
    when :limited then User::ListingAccess::LIMITED
    when :none then User::ListingAccess::NONE
    end.to_s
    choose "user_listing_access_#{id}"
    click_on 'Save changes'
  end

  def user_should_have_listing_access(level)
    should_be_on_user_details_page(user)
    user.reload
    case level
    when :undetermined then user.should be_undetermined_listing_access
    when :full then user.should be_full_listing_access
    when :limited then user.should be_limited_listing_access
    when :none then user.should be_no_listing_access
    end
  end
end
