require './acceptance/spec_helper'

feature 'Secret seller' do
  before do
    login_as "starbuck@galactica.mil"
  end

  scenario 'submit with item' do
    visit_new_secret_seller_item_page
    submit_with_item
    should_see_thanks
  end

  scenario 'without item' do
    visit_new_secret_seller_item_page
    submit_without_item
    should_not_see_thanks
  end

  def visit_new_secret_seller_item_page
    visit(new_secret_seller_item_path)
  end

  def submit_with_item
    fill_in('item_title', with: 'Beachhead GI Joe action figure')
    fill_in('item_description', with: 'I already have two of these. Mint condition in package, never opened.')
    fill_in('item_price', with: 99.99)
    attach_file 'item_photo', fixture('handbag.jpg')
    submit_form
  end

  def submit_without_item
    submit_form
  end

  def should_see_thanks
    page.should have_thanks
  end

  def should_not_see_thanks
    page.should_not have_thanks
  end

  def submit_form
    click_on('item_save')
  end

  def have_thanks
    have_selector('[data-role=thanks]')
  end
end
