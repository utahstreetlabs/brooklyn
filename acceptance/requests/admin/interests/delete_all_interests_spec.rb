require './acceptance/spec_helper'

feature 'Delete all interests', js: true do
  let(:interest_count) { 3 }

  background do
    FactoryGirl.create_list(:interest, interest_count)
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_interests_path
    delete_all_interests
    current_path.should == admin_interests_path
    page.should have_no_interests
  end

  scenario 'without selecting any interests' do
    visit admin_interests_path
    delete_all_interests_without_selecting_any
    current_path.should == admin_interests_path
    page.should have_interests
  end

  def delete_all_interests
    check 'toggle_all'
    click_on 'Delete selected'
  end

  def delete_all_interests_without_selecting_any
    click_on 'Delete selected'
  end

  matcher :have_no_interests do
    match do |page|
      page.all('[data-interest]').should be_empty
    end
  end

  matcher :have_interests do
    match do |page|
      page.all('[data-interest]').size.should == interest_count
    end
  end
end
