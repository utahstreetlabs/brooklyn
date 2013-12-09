require './acceptance/spec_helper'

feature "Feature listing as admin" do
  let(:listing) { given_listing(tags: ['red', 'blue']) }

  background do
    login_as "starbuck@galactica.mil", admin: true
  end

  scenario "feature the listing in its category" do
    visit admin_listing_path(listing.id)
    find('[data-action=feature-in-category]').click
    page.should have_flash_message(:notice, 'admin.listings.featured_for_category',
      category: listing.category.name)
    page.should have_css('[data-action=dont-feature-in-category]')
  end

  scenario "stop featuring the listing in its category" do
    listing.features.create!(featurable: listing.category)
    visit admin_listing_path(listing.id)
    find('[data-action=dont-feature-in-category]').click
    page.should have_flash_message(:notice, 'admin.listings.not_featured_for_category',
      category: listing.category.name)
    page.should have_css('[data-action=feature-in-category]')
  end

  scenario "feature the listing in a tag page", js: true do
    visit admin_listing_path(listing.id)
    find('[data-target="#feature_tags-modal"]').click
    check listing.tags.first.name
    click_on 'Save'
    wait_for(2)
    page.should have_flash_message(:notice, 'admin.listings.featured_for_tags', tags: listing.tags.first.name)
  end

  scenario "stop featuring the listing on a tag page", js: true do
    listing.features.create!(featurable: listing.tags.first)
    visit admin_listing_path(listing.id)
    find('[data-target="#feature_tags-modal"]').click
    uncheck listing.tags.first.name
    click_on 'Save'
    wait_for(2)
    page.should have_flash_message(:notice, 'admin.listings.not_featured_for_tags')
  end
end
