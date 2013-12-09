require './acceptance/spec_helper'

feature 'Merge a tag into another tag' do
  let(:tag1) { FactoryGirl.create(:tag, name: 'Iguana') }
  let(:tag2) { FactoryGirl.create(:tag, name: 'Sheepskin') }

  background do
    login_as 'starbuck@galactica.mil', admin: true
    visit admin_tag_path(tag1.id)
  end

  scenario 'successfully' do
    fill_in 'Tag name', with: tag2.name
    click_on "Merge into #{tag1.name}"
    current_path.should == admin_tag_path(tag1.id)
    page.should have_flash_message(:notice, 'admin.tags.merged', name: tag1.name)
    page.should have_css("[data-subtag='#{tag2.id}']")
  end
end
