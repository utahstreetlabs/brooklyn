require './acceptance/spec_helper'

feature 'Delete interest', js: true do
  background do
    FactoryGirl.create(:interest)
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_interests_path
    delete_interest
    current_path.should == admin_interests_path
    page.should have_no_interests
  end

  def delete_interest
    find('[data-action=delete]').click
    accept_alert
  end

  matcher :have_no_interests do
    match do |page|
      page.all('[data-interest]').should be_empty
    end
  end
end
