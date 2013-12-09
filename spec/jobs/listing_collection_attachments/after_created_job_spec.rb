require 'spec_helper'

describe ListingCollectionAttachments::AfterCreatedJob do
  subject { ListingCollectionAttachments::AfterCreatedJob }

  describe '::inject_listing_save_notification' do
    context 'when seller is collection owner' do
      it 'does not inject' do
        collection = FactoryGirl.create(:collection)
        listing = FactoryGirl.create(:active_listing, seller: collection.owner)
        subject.expects(:inject_notification).never
        subject.inject_listing_save_notification(listing, collection)
      end
    end

    context 'when seller is not collection owner' do
      it 'injects' do
        collection = FactoryGirl.create(:collection)
        listing = FactoryGirl.create(:active_listing)
        subject.expects(:inject_notification)
        subject.inject_listing_save_notification(listing, collection)
      end
    end
  end

  describe '::send_listing_save_email' do
    context 'when seller is collection owner' do
      it 'does not send' do
        collection = FactoryGirl.create(:collection)
        listing = FactoryGirl.create(:active_listing, seller: collection.owner)
        subject.expects(:inject_email).never
        subject.send_listing_save_email(listing, collection)
      end
    end

    context 'when seller is not collection owner' do
      it 'sends' do
        collection = FactoryGirl.create(:collection)
        listing = FactoryGirl.create(:active_listing)
        listing.seller.stubs(:allow_email?).returns(true)
        subject.expects(:send_email)
        subject.send_listing_save_email(listing, collection)
      end
    end
  end

  describe '::add_listing_to_recent_cache' do
    let(:listing) { stub_listing 'Bitten-off bat head', seller: stub_user('Ozzy Osbourne') }

    it "adds a listing to a user's recent saved listings cache" do
      subject.add_listing_to_recent_cache(listing)
      listing.seller.recent_saved_listing_ids.should == [listing.id]
    end

    it "does not add a listing to a user's recent listings cache when the listing is already cached" do
      listing.seller.recent_saved_listing_ids << listing.id
      subject.add_listing_to_recent_cache(listing)
      listing.seller.recent_saved_listing_ids.should == [listing.id]
    end
  end
end
