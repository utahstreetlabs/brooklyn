require './acceptance/spec_helper'

feature 'Create collection from profile page', js: true do
  let(:collection) { given_collection }
  before do
    login_as(collection.owner.email)
    visit public_profile_collections_path(collection.owner)
  end

  scenario 'succeeds' do
    create_collection
    collection_should_be_created
  end

  def create_collection
    open_create_modal do
      fill_in('collection_name', with: 'Transformers')
    end
    save_create_modal
    close_listings_modal
  end

  def collection_should_be_created
    # since we aren't automatically updating the page yet, just reload it
    visit public_profile_collections_path(collection.owner)
    page.should have_content('Transformers')
  end

  def open_create_modal(&block)
    find('#add-collection-card-button').click
    within_modal('collection-create', &block)
  end

  def save_create_modal
    save_modal('collection-create')
  end

  def close_listings_modal
    close_modal('collection-create-listings')
  end
end
