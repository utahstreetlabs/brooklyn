require './acceptance/spec_helper'

feature 'Manage tags' do
  background do
    given_tags ['leather', 'lace', 'snakeskin']
    login_as 'starbuck@galactica.mil', admin: true
    visit admin_tags_path
  end

  scenario 'delete selected tags', js: true do
    check_tag 'leather'
    check_tag 'lace'
    click_on 'Delete all selected tags'
    accept_alert
    current_path.should == admin_tags_path
    page.should have_flash_message(:notice, 'admin.tags.destroyed_all')
    page.should have_tag('snakeskin')
  end

  scenario 'delete individual tag', js: true do
    click_on_delete 'snakeskin'
    accept_alert
    current_path.should == admin_tags_path
    page.should have_flash_message(:notice, 'admin.tags.removed', name: 'snakeskin')
    page.should_not have_tag('snakeskin')
  end

  scenario 'merge tags', js: true do
    check_tag 'leather'
    check_tag 'lace'
    click_on_merge 'snakeskin'
    current_path.should == admin_tags_path
    page.should have_flash_message(:notice, 'admin.tags.merged', name: 'snakeskin')
    page.should have_tag('snakeskin')
  end
end
