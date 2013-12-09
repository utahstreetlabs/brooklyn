require './acceptance/spec_helper'

feature 'Update a tag' do
  let(:tag) { FactoryGirl.create(:tag, name: 'Iguana') }

  background do
    login_as 'starbuck@galactica.mil', admin: true
    visit edit_admin_tag_path(tag.id)
  end

  scenario 'successfully' do
    fill_in 'Name', with: 'Sheepskin'
    click_on 'Save changes'
    current_path.should == admin_tag_path(tag.id)
    page.should have_flash_message(:notice, 'admin.tags.updated', name: 'Sheepskin')
    tag.reload.slug.should == 'sheepskin'
  end
end
