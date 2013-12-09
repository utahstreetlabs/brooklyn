require './acceptance/spec_helper'

feature 'Remove all interests from onboarding', js: true do
  let(:interest_count) { 3 }

  background do
    given_global_interest
    given_onboarding_interests(interest_count)
    login_as 'roslin@galactica.mil', admin: true
  end

  scenario 'happily' do
    visit admin_interests_path
    remove_all_interests
    current_path.should == admin_interests_path
    page.should have_no_interests_with_onboarding
  end

  scenario 'without selecting any interests' do
    visit admin_interests_path
    remove_all_interests_without_selecting_any
    current_path.should == admin_interests_path
    page.should have_all_interests_with_onboarding
  end

  def remove_all_interests
    check 'toggle_all'
    click_on 'Remove selected from onboarding'
  end

  def remove_all_interests_without_selecting_any
    click_on 'Remove selected from onboarding'
  end

  matcher :have_all_interests_with_onboarding do
    match do |page|
      page.all('[data-interest]').each do |i|
        within(i) do
          # global interest is never in onboarding list
          expected = i['data-interest'] == Interest.global.id.to_s ? 'no' : 'yes'
          page.find('[data-role=onboarding]').text.strip.should == expected
        end
      end
    end
  end

  matcher :have_no_interests_with_onboarding do
    match do |page|
      page.all('[data-interest]').each do |i|
        within(i) do
          page.find('[data-role=onboarding]').text.strip.should == 'no'
        end
      end
    end
  end
end
