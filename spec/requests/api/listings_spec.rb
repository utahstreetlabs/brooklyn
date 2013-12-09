require 'spec_helper'

describe 'Create listing' do
  context 'with valid credentials' do
    let(:api_config) { FactoryGirl.create(:api_config) }
    let(:user) { api_config.user }
    let(:params) { {access_token: api_config.token} }

    context 'and valid input' do
      let(:category) { FactoryGirl.create(:category) }
      before do
        params[:listing] = {
          title: 'Hamburgler doll',
          description: 'Wicked awesome',
          price: '250.00',
          category: category.slug
        }
      end

      context 'and a remote photo' do
        let(:source_uid) { 'cafebebe' }
        let(:uri) { 'http://example.com/hamburgler.jpg' }
        before do
          stub_carrierwave_download!(uri, fixture_file('hamburgler.jpg'))
          params[:listing][:photos] = [{'source_uid' => source_uid, 'link' => {'href' => uri}}]
          post '/v1/listings', params
        end
        subject { response }

        its(:status) { should == 201 }
        its(:headers) { subject['Location'].should be }
        its(:json) { subject[:slug].should be }
        it "attaches the photo" do
          Listing.find_by_slug(subject.json[:slug]).photos.should have(1).photo
        end
      end

      context 'and an uploaded photo' do
        before do
          params[:listing][:photo] = fixture_file_upload('hamburgler.jpg', 'image/jpg')
          post '/v1/listings', params
        end
        subject { response }

        its(:status) { should == 201 }
        its(:headers) { subject['Location'].should be }
        its(:json) { subject[:slug].should be }
        it "attaches the photo" do
          Listing.find_by_slug(subject.json[:slug]).photos.should have(1).photo
        end
      end

      context 'and no photos' do
        before { post '/v1/listings', params }
        subject { response }

        its(:status) { should == 201 }
        its(:headers) { subject['Location'].should be }
        its(:json) { subject[:slug].should be }
      end

      context 'and empty param' do
        before { post '/v1/listings', params.merge(empty: true) }
        subject { response }

        its(:status) { should == 201 }
        its(:headers) { subject['Location'].should be }
        its(:headers) { subject['Link'].should be }
        its(:body) { should be_empty }
      end
    end

    context 'and invalid input' do
      before { post '/v1/listings', params }
      subject { response }

      its(:status) { should == 400 }
      its(:json) { subject[:invalid_fields].should be }
    end
  end

  context 'with invalid credentials' do
    before { post '/v1/listings' }
    subject { response }

    its(:status) { should == 401 }
    its(:json) { subject[:error].should == 'invalid_token' }
  end
end
