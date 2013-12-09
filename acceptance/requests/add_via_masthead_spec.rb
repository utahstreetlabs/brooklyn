require './acceptance/spec_helper'

feature 'Via masthead, add', js: true do
  include_context 'adding via masthead'

  before do
    login_as "starbuck@galactica.mil"
  end

  context "listing from external source that can be scraped" do
    scenario 'succeeds' do
      masthead_add_listing_from_web(true)
      should_be_on_active_listing_page
    end

    scenario "succeeds when source contains an image with spaces in the filename" do
      masthead_add_listing_from_web(true, space_in_filename: true)
      should_be_on_active_listing_page
    end
  end

  scenario 'listing from an external source that cannot be scraped' do
    masthead_add_listing_from_web(false)
    should_see_failure_to_fetch_content
  end

  scenario 'listing by manually entering it' do
    masthead_add_listing_manually
    should_be_on_new_listing_page
  end

  scenario 'the external bookmarklet' do
    masthead_add_listing_external_bookmarklet
    should_be_on_info_extras_page
  end

  scenario 'collection' do
    masthead_add_collection
    should_be_on_home_page
  end

  def should_be_on_active_listing_page
    retry_expectations do
      listing = Listing.last
      expect(listing).to be
      expect(listing.slug).to eq('master-of-puppets-limited-edition-vinyl')
      expect(listing).to be_active
      expect(current_path).to eq(listing_path(listing))
    end
  end

  def should_see_failure_to_fetch_content
    within_modal(masthead_add_listing_from_web_modal_id) do
      page.should have_selector('.alert-error')
    end
  end

  def should_be_on_new_listing_page
    retry_expectations do
      current_path.should match(/\/listings\/new\-listing\-\d+\/setup/)
    end
  end

  def should_be_on_info_extras_page
    retry_expectations do
      current_path.should eq('/info/extras')
    end
  end

  def should_be_on_home_page
    current_path.should match(/\//)
  end
end
