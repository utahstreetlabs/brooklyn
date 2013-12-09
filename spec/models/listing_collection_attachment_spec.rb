require 'spec_helper'

describe ListingCollectionAttachment do
  describe 'after creation' do
    it 'enqueues ListingCollectionAttachments::AfterCreatedJob' do
      collection = FactoryGirl.create(:collection)
      listing = FactoryGirl.create(:active_listing)
      ListingCollectionAttachments::AfterCreatedJob.expects(:enqueue).with(is_a(Integer))
      ListingCollectionAttachment.create!(collection_id: collection.id, listing_id: listing.id)
    end
  end

  describe '#after_destroy' do
    it 'enqueues ListingCollectionAttachments::AfterDestroyedJob' do
      collection = FactoryGirl.create(:collection)
      listing = FactoryGirl.create(:active_listing)
      lca = ListingCollectionAttachment.create!(collection_id: collection.id, listing_id: listing.id)
      ListingCollectionAttachments::AfterDestroyedJob.expects(:enqueue).with(lca.id)
      lca.destroy
    end
  end
end
