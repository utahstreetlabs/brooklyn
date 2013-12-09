require './acceptance/spec_helper'

feature "Manage admin access" do
  let!(:user) { given_registered_user }

  background do
    given_global_interest
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'grant admin access', js: true do
    user.should_not be_admin
    visit admin_user_path(user.id)
    page_should_have_grant_admin_button(user, true)
    page_should_have_revoke_admin_button(user, false)
    grant_admin_access(user)
    page_should_have_granted_flash_notice(user)
    user.reload
    user.should be_admin
  end

  scenario 'revoke admin access', js: true do
    user.update_attribute(:admin, true)
    visit admin_user_path(user.id)
    page_should_have_grant_admin_button(user, false)
    page_should_have_revoke_admin_button(user, true)
    revoke_admin_access(user)
    page_should_have_revoked_flash_notice(user)
    user.reload
    user.should_not be_admin
  end

  def page_should_have_grant_admin_button(user, visible)
    page.has_css?('[data-action=admin-on]', visible: visible).should be_true
  end

  def page_should_have_revoke_admin_button(user, visible)
    page.has_css?('[data-action=admin-off]', visible: visible).should be_true
  end

  def grant_admin_access(user)
    find('[data-action=admin-on]').click
    wait_for(2)
  end

  def revoke_admin_access(user)
    find('[data-action=admin-off]').click
    wait_for(2)
  end

  def page_should_have_granted_flash_notice(user)
    page.should have_flash_message(:notice, 'admin.users.admin.created', name: user.name)
  end

  def page_should_have_revoked_flash_notice(user)
    page.should have_flash_message(:notice, 'admin.users.admin.deleted', name: user.name)
  end
end
