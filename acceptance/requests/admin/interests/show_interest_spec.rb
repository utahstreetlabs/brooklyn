require './acceptance/spec_helper'

feature 'Show interest' do
  let(:user_count) { 3 }
  let(:interest) { given_suggested_user_list(user_count) }

  background do
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_interest_path(interest)
    page.should have_cover_photo
    page.should have_users
  end

  matcher :have_cover_photo do
    match do |page|
      page.should have_css('[data-role=cover_photo]')
    end
  end

  matcher :have_users do
    match do |page|
      page.all('[data-user]').size.should == user_count
    end
  end
end
