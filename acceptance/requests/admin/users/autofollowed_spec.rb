require './acceptance/spec_helper'

feature "Manage user autofollow" do
  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  let!(:user) { given_registered_user }

  scenario 'adds user to autofollow list', js: true do
    visit admin_user_path(user.id)
    user_should_not_be_autofollowed(user)
    page_should_have_add_to_autofollow_button(user, true)
    page_should_have_remove_from_autofollow_button(user, false)
    add_user_to_autofollowed_list(user)
    page_should_have_added_flash_notice(user)
    user_should_be_autofollowed(user)
  end

  scenario 'removes user from autofollow list', js: true do
    user.add_to_autofollow_list!
    visit admin_user_path(user.id)
    user_should_be_autofollowed(user)
    page_should_have_add_to_autofollow_button(user, false)
    page_should_have_remove_from_autofollow_button(user, true)
    remove_user_from_autofollowed_list(user)
    page_should_have_removed_flash_notice(user)
    user_should_not_be_autofollowed(user)
  end

  def page_should_have_add_to_autofollow_button(user, visible)
    page.has_css?('[data-action=autofollow-on]', visible: visible).should be_true
  end

  def page_should_have_remove_from_autofollow_button(user, visible)
    page.has_css?('[data-action=autofollow-off]', visible: visible).should be_true
  end

  def add_user_to_autofollowed_list(user)
    find('[data-action=autofollow-on]').click
    wait_for(2)
  end

  def remove_user_from_autofollowed_list(user)
    find('[data-action=autofollow-off]').click
    wait_for(2)
  end

  def page_should_have_added_flash_notice(user)
    page.should have_flash_message(:notice, 'admin.users.autofollows.added', name: user.name)
  end

  def page_should_have_removed_flash_notice(user)
    page.should have_flash_message(:notice, 'admin.users.autofollows.removed', name: user.name)
  end
end
