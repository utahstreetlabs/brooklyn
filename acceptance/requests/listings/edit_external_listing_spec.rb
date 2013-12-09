require './acceptance/spec_helper'

feature 'Edit internal listing', js: true do
  let!(:listing) { FactoryGirl.create(:external_listing) }

  background do
    login_as listing.seller.email
    visit_edit_listing_page
  end

  scenario 'changes an attribute' do
    fill_in('listing_title', with: 'New title')
    submit_edit_listing_form
    should_be_on_listing_page
    expect(page).to have_content('New title')
  end

  scenario 'omits unsupported fields' do
    expect(page).to have_no_css('#listing_dimension_condition')
    expect(page).to have_no_css('#listing_original_price')
    expect(page).to have_no_css('#listing_shipping')
    expect(page).to have_no_css('#listing_shipping_option_code')
    expect(page).to have_no_css('#listing_handling_duration')
    expect(page).to have_no_css('[data-role=shipping]') # price box
  end

  def visit_edit_listing_page
    visit(edit_listing_path(listing))
  end

  def submit_edit_listing_form
    click_on('preview_listing')
  end

  def should_be_on_listing_page
    retry_expectations do
      expect(current_path).to eq(listing_path(listing))
    end
  end
end
