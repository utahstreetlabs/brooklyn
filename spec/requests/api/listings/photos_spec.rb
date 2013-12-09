require 'spec_helper'

describe 'Create listing photo' do
  let(:user) { FactoryGirl.create(:registered_user) }
  let(:listing) { FactoryGirl.create(:active_listing, seller: user) }

  context 'with valid credentials' do
    let(:api_config) { FactoryGirl.create(:api_config, user: user) }
    let(:params) { {access_token: api_config.token} }

    context 'and an uploaded photo' do
      let(:category) { FactoryGirl.create(:category) }
      before do
        params[:empty] = true
        params[:listing] = {
          title: 'Hamburgler doll',
          description: 'Wicked awesome',
          price: '250.00',
          category: category.slug
        }
        params[:listing][:photo] = fixture_file_upload('hamburgler.jpg', 'image/jpg')
        post "/v1/listings/#{listing.slug}/photos", params
      end
      subject { response }

      its(:status) { should == 201 }
      its(:headers) { subject['Location'].should be }
      its(:headers) { subject['Link'].should be }
      it "attaches the photo" do
        listing.photos.should have(2).photos
      end
    end

    context 'and a remote photo' do
      let(:source_uid) { 'cafebebe' }
      let(:uri) { 'http://example.com/hamburgler.jpg' }
      before do
        stub_carrierwave_download!(uri, fixture_file('hamburgler.jpg'))
        params[:listing_photo] = {'source_uid' => source_uid, 'link' => {'href' => uri}}
        post "/v1/listings/#{listing.slug}/photos", params
      end
      subject { response }

      its(:status) { should == 201 }
      its(:headers) { subject['Location'].should be }
      its(:json) { subject[:photo][:id].should be }
      its(:json) { subject[:photo][:source_uid].should == source_uid }
      its(:json) { subject[:photo][:link].should be }
      it "attaches the photo" do
        listing.photos.should have(2).photos
      end
    end
  end

  context 'with invalid credentials' do
    before { post "/v1/listings/#{listing.slug}/photos" }
    subject { response }

    its(:status) { should == 401 }
    its(:json) { subject[:error].should == 'invalid_token' }
  end
end
