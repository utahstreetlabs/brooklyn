require './acceptance/spec_helper'

feature "Create listing as guest", %q{
  In order to list an item with as little friction as possible
  As a prospective seller
  I want to create a listing without being forced to log in first
} do

  include_context "with facebook test user"

  let! :handbags do
    given_category "Handbags"
  end

  background do
    given_tags ["leather", 'lovable']
    given_size_tag "Medium"
    given_dimension "Condition", category: handbags, values: [
      "New with tags", "New without tags", "Used - excellent", "Used - fair"
    ]
  end

  before do
    visit root_path
    fb_user_login
  end

  scenario "happily", js: true do
    enter_listing_flow
    enter_flow_should_succeed
    fill_in_listing_form
    preview_listing
    preview_listing_should_succeed
    log_in_and_publish_should_succeed
  end

  scenario "with existing incomplete listing", js: true do
    # create guest and listing but don't complete the listing
    enter_listing_flow
    enter_flow_should_succeed
    # now, start the flow over
    enter_listing_flow
    enter_flow_should_succeed
    fill_in_listing_form
    preview_listing
    preview_listing_should_succeed
    log_in_and_publish_should_succeed
  end

  scenario "with existing inactive listing", js: true do
    # create guest and complete listing
    enter_listing_flow
    enter_flow_should_succeed
    fill_in_listing_form
    preview_listing
    preview_listing_should_succeed
    # now, start the flow over
    enter_listing_flow
    preview_listing_should_succeed
    log_in_and_publish_should_succeed
  end

  scenario "save draft", js: true do
    enter_listing_flow
    fill_in 'listing_price', with: '10'
    submit_draft_form
    expect(current_path).to eq(setup_listing_path(created_listing))
  end

  scenario "should not be allowed when credentials are for inactive user", js: true do
    user = FactoryGirl.create(:inactive_user)
    enter_listing_flow
    enter_flow_should_succeed
    find('[data-action=login]').click
    fill_in 'email', :with => user.email
    fill_in 'password', :with => "test"
    click_on 'Log in'
    # don't login
    retry_expectations do
      expect(page).to have_no_content(user.display_name)
    end
    # show error
    expect(page).to have_css('[data-role=login-error]')
  end

  scenario "happily", js: true do
    enter_listing_flow
    enter_flow_should_succeed
    fill_in_listing_form
    preview_listing
    preview_listing_should_succeed
    click_facebook_connect
    accept_insane_gdp_facebook_permissions
    complete_full_registration
    publish_listing
    publish_listing_should_succeed
  end

  def created_guest
    User.last || raise("No user")
  end

  def created_listing
    Listing.last || raise("No listings!")
  end

  def enter_listing_flow
    # XXX: there is no current point (2/1/2012) from the logged out home, only external links, so hitting the
    # new listing path directly.  that should change shortly, though, and this method should be reverted to include
    # that step.
    # visit root_path
    # wait_a_sec_for_selenium
    # click_link 'List my stuff'
    visit new_listing_path
  end

  def enter_flow_should_succeed
    retry_expectations { expect(current_path).to match(/\/listings\/new-listing-\d+\/setup/) }
  end

  def preview_listing
    click_button 'preview_listing'
  end

  def preview_listing_should_succeed
    retry_expectations { expect(current_path).to eq(listing_path(created_listing)) }
    expect(page).to have_content(I18n.t('listings.show.seller.status.inactive_guest'))
  end

  def log_in_from_preview_page
    find('[data-action=login]').click
    login_as 'starbuck@galactica.mil', on_current_page: true
  end

  def publish_listing
    find('[data-action=activate]').click
  end

  def publish_listing_should_succeed
    retry_expectations { expect(current_path).to eq(listing_path(created_listing)) }
    expect(page).to have_content(I18n.t('listings.show.seller.status.active'))
  end

  def log_in_and_publish_should_succeed
    log_in_from_preview_page
    publish_listing
    publish_listing_should_succeed
  end

  def edit_listing
    find('[data-action=edit]').click
  end

  def edit_listing_should_succeed
    expect(current_path).to eq(edit_listing_path(created_listing))
    expect(page).to have_content "Edit your listing"
  end

  def save_listing
    click_button 'preview_listing'
  end

  def save_listing_should_succeed
    expect(current_path).to eq(listing_path(created_listing))
    expect(page).to have_content "Your listing is almost live!"
  end

  def submit_draft_form
    click_button "save_draft"
  end
end
