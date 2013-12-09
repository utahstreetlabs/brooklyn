require './acceptance/spec_helper'

feature 'Create a tag' do
  background do
    login_as 'starbuck@galactica.mil', admin: true
    visit new_admin_tag_path
  end

  scenario 'successfully' do
    fill_in 'Name', with: 'Iguana'
    click_on 'Save changes'
    tag = Tag.find_by_slug('iguana')
    current_path.should == admin_tag_path(tag.id)
    page.should have_flash_message(:notice, 'admin.tags.created', name: 'Iguana')
  end
end
