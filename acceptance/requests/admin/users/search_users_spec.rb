require './acceptance/spec_helper'

feature "Search users as admin" do
  let(:user1) { FactoryGirl.create(:registered_user) }
  let(:user2) { FactoryGirl.create(:registered_user) }

  background do
    login_as('starbuck@galactica.mil', admin: true)
  end

  scenario "finds user by email" do
    visit admin_users_path
    search_datagrid user1.email
    page.should have_content(user1.email)
    page.should_not have_content(user2.email)
  end
end
