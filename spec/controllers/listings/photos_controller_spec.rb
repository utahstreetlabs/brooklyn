require 'spec_helper'

describe Listings::PhotosController do
  let(:listing) { stub('listing', id: 56789) }
  let(:slug) { 'a-listing' }
  let(:photos) { stub('photos', all: []) }
  let(:photo) { stub(id: 1) }

  before do
    scope = mock('listing-scope')
    Listing.stubs(:scoped).returns(scope)
    Listing.stubs(:find_in_batches).returns(nil)
    scope.stubs(:find_by_slug!).with(slug).returns(listing)
    listing.stubs(:photos).returns(photos)
  end

  context "#create" do
    let(:file) { [fixture_file_upload('handbag.jpg', 'image/jpg')] }
    let(:photo_params) { {file: [file]}.stringify_keys! }
    let(:build_params) { [{background_processing: true, 'file' => file}] }

    it_behaves_like "xhr secured against anonymous users" do
      before { submit_upload_photo_form }
    end

    context "by an rfb" do
      before { act_as_rfb }

      it "is disallowed" do
        submit_upload_photo_form
        response.should redirect_to(listing_path(listing))
      end
    end

    context "by the seller" do
      before do
        act_as_seller
        photos.stubs(:build).with(build_params).returns([photo])
      end

      context "for a pending listing" do
        context "normally" do
          before do
            photo.expects(:save).with().once.returns(true)
          end

          it "assigns photo" do
            submit_upload_photo_form(photo_params)
            assigns(:photos).should == [photo]
          end

          it "renders a jsend response" do
            submit_upload_photo_form(photo_params)
            response.should be_jsend_success
          end
        end

        context "with errors" do
          before do
            photo.expects(:save).with().once.returns(false)
            photo.stubs(:errors).returns({})
          end

          it "assigns photo" do
            submit_upload_photo_form(photo_params)
            assigns(:photos).should == [photo]
          end

          it "renders jsend error" do
            submit_upload_photo_form(photo_params)
            response.should be_jsend_error
          end
        end
      end

      context "for an active listing" do
        context "normally" do
          before do
            photo.expects(:save).with().once.returns(true)
          end

          it "assigns photo" do
            submit_upload_photo_form(photo_params)
            assigns(:photos).should == [photo]
          end

          it "renders a jsend response" do
            submit_upload_photo_form(photo_params)
            response.should be_jsend_success
          end
        end

        context "with errors" do
          before do
            photo.expects(:save).with().once.returns(false)
            photo.stubs(:errors).returns({})
          end

          it "assigns photo" do
            submit_upload_photo_form(photo_params)
            assigns(:photos).should == [photo]
          end

          it "renders a jsend response" do
            submit_upload_photo_form(photo_params)
            response.should be_jsend_error
          end
        end
      end
    end

    def submit_upload_photo_form(photo_params = {})
      xhr :post, :create, {:format => :json, :listing_id => slug, :listing_photo => photo_params}
    end
  end

  context "#update" do
    let(:file) { fixture_path + 'handbag.jpg' }
    let(:photo_params) { {remote_file_url: file}.stringify_keys! }
    let(:build_params) { photo_params.merge( background_processing: true) }

    it_behaves_like "xhr secured against anonymous users" do
      before { submit_replace_photo_form }
    end

    context "by an rfb" do
      before { act_as_rfb }

      it "is disallowed" do
        submit_replace_photo_form
        response.should redirect_to(listing_path(listing))
      end
    end

    context "for an active listing" do
      before do
        act_as_seller
        ListingPhoto.expects(:find).with(photo.id.to_s).returns(photo)
        photo.expects(:background_processing=).with(true)
      end

      context "normally" do
        before do
          photo.expects(:update_attributes).with(photo_params).once.returns(true)
        end

        it "assigns photo" do
          submit_replace_photo_form(photo_params)
          assigns(:photo).should == photo
        end

        it "renders a jsend response" do
          submit_replace_photo_form(photo_params)
          response.should be_jsend_success
        end
      end

      context "with errors" do
        before do
          photo.expects(:update_attributes).once.returns(false)
          photo.stubs(:errors).returns({})
        end

        it "assigns photo" do
          submit_replace_photo_form(photo_params)
          assigns(:photo).should == photo
        end

        it "renders a jsend response" do
          submit_replace_photo_form(photo_params)
          response.should be_jsend_error
        end
      end
    end

    def submit_replace_photo_form(photo_params = {})
      xhr :put, :update, {format: :json, listing_id: slug, id: photo.id, listing_photo: photo_params}
    end
  end

  context "#destroy" do
    let(:photo_id) { 123 }

    it_behaves_like "xhr secured against anonymous users" do
      before { click_delete_button }
    end

    context "by an rfb" do
      before { act_as_rfb }

      it "is disallowed" do
        click_delete_button
        response.should redirect_to(listing_path(listing))
      end
    end

    context "by the seller" do
      before do
        act_as_seller
        photos.expects(:destroy).with(photo_id.to_s).once
        # has_photos? is only used to determine which flash message to set, and we don't bother testing flash
        listing.stubs(:has_photos?).returns(true)
      end

      it "renders a jsend response" do
        click_delete_button
        response.should be_jsend_success
      end
    end

    def click_delete_button
      xhr :delete, :destroy, format: :json, listing_id: slug, id: photo_id
    end
  end

  context "#make_primary" do
    let (:photo_id) { 23 }
    it_behaves_like 'secured against anonymous users' do
      before { make_primary }
    end

    context "by the seller" do
      before do
        act_as_seller
        photos.stubs(:find).with(photo_id.to_s).returns(photo)
      end

      it "moves the photo to the top" do
        photo.expects(:move_to_top).returns(true)
        make_primary
      end
    end

    def make_primary
      post :make_primary, listing_id: slug, photo_id: photo_id
    end
  end

  def act_as_rfb
    user = act_as_stub_user
    listing.stubs(:sold_by?).with(user).returns(false)
  end

  def act_as_seller
    user = act_as_stub_user
    listing.stubs(:sold_by?).with(user).returns(true)
  end
end
