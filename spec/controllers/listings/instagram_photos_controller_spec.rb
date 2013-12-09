require 'spec_helper'

describe Listings::InstagramPhotosController do
  let(:slug) { 'a-listing' }
  let(:photo) { stub('photo', source_uid: '12211') }
  let(:oldphoto) do
    {'id' => '9999', 'source_uid' => '12210'}
  end
  let(:photos) { [oldphoto] }
  let(:listing) { stub('listing', slug: 'Big Numbers #4 Comic', id: '56789', photos: photos) }
  let(:url) { 'http://dl.instagram.com/photo.jpg' }

  before do
    scope = mock('listing-scope')
    Listing.stubs(:scoped).returns(scope)
    scope.stubs(:find_by_slug!).with(listing.slug).returns(listing)
    Network::Instagram.stubs(:active).returns(true)
  end

  context "#index" do
    it_behaves_like "secured against anonymous users" do
      before { get_instagram_recent_media(listing) }
    end

    context "by a user" do
      let(:profile) { stub('profile', network: 'instagram') }

      before do
        user = act_as_seller
        profile.stubs(:photos).with(is_a(Hash)).returns({'56789' => oldphoto})
        user.person.stubs(:for_network).returns(profile)
        user.person.stubs(:connected_to?).with(:instagram).returns(true)
      end

      it "renders media feed" do
        get_instagram_recent_media(listing)
        assigns[:photos].should == photos
        response.should be_jsend_success
      end
    end

    def get_instagram_recent_media(listing)
      get :index, listing_id: listing.slug, format: :json
    end
  end

  context "#update" do
    let(:import_params) do
      { source_uid: photo.source_uid }
    end

    it_behaves_like "xhr secured against anonymous users" do
      before { import_photo_from_instagram }
    end

    context "by an rfb" do
      before { act_as_rfb }

      it "is disallowed" do
        import_photo_from_instagram
        response.should be_jsend_unauthorized
      end
    end

    context "by the seller" do
      let(:file) { stub('file') }
      let(:profile) { stub('profile', network: 'instagram') }

      before do
        act_as_seller
        photos.stubs(:build).with(import_params).returns(photo)
        photo.stubs(:file).returns(file)
        photos.stubs(:all).returns(photos)
      end

      it "successfully imports the photo" do
        file.expects(:download!).returns
        photo.expects(:save!).returns(true)
        listing.stubs(:has_sourced_photo?).with(photo.source_uid).returns(false)
        import_photo_from_instagram(url: url)
        response.should be_jsend_success
      end

      it "renders jsend fail on save failure" do
        photo.expects(:save!).raises(ActiveRecord::RecordNotSaved)
        file.expects(:download!).returns
        listing.stubs(:has_sourced_photo?).with(photo.source_uid).returns(false)
        photo.stubs(:errors).returns({})
        import_photo_from_instagram(import_params)
        response.should be_jsend_failure
      end

      it "renders jsend error if photo exists" do
        listing.stubs(:has_sourced_photo?).with(photo.source_uid).returns(true)
        import_photo_from_instagram(import_params)
        response.should be_jsend_error
      end

      it "renders jsend error if url is malformed" do
        listing.stubs(:has_sourced_photo?).with(photo.source_uid).returns(false)
        import_photo_from_instagram(import_params)
        response.should be_jsend_error
      end
    end

    def import_photo_from_instagram(import_params={})
      xhr :put, :update, {:format => :json, :listing_id => listing.slug, :id => photo.source_uid, :url => url}
    end
  end

  def act_as_rfb
    user = act_as_stub_user
    listing.stubs(:sold_by?).with(user).returns(false)
    user.person.stubs(:connected_to?).with(:instagram).returns(false)
    user
  end

  def act_as_seller
    user = act_as_stub_user
    listing.stubs(:sold_by?).with(user).returns(true)
    user.person.stubs(:for_network).returns(profile)
    user.person.stubs(:connected_to?).with(:instagram).returns(true)
    user
  end
end
