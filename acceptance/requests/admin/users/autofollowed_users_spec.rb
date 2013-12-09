require './acceptance/spec_helper'

feature "Autofollowed users" do
  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario "removes user from list", js: true do
    user = given_registered_user
    user.add_to_autofollow_list!
    visit admin_users_autofollows_path
    user_should_be_autofollowed(user)
    remove_user(user)
    page_should_have_removed_flash_notice(user)
    user_should_not_be_autofollowed(user)
  end

  def remove_user(user)
    within_autofollowed_user(user) do
      find("[data-action='remove-autofollow']").click
    end
    accept_alert
    wait_for(2)
  end

  def page_should_have_removed_flash_notice(user)
    page.should have_flash_message(:notice, 'admin.users.autofollows.removed', name: user.name)
  end

  def within_autofollowed_user(user, &block)
    within("[data-user='#{user.id}']", &block)
  end
end

