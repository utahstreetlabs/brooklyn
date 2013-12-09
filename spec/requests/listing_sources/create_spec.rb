require 'spec_helper'

describe 'Create listing source' do
  let(:url) { '/listing_sources' }
  let(:source_url) { 'http://example.com/thinger' }

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      xhr :post, url, format: :json
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    context 'and the source is scraped' do
      let(:source) { FactoryGirl.build(:listing_source, url: source_url) }
      before do
        ListingSource.expects(:scrape).with(source_url).returns(source)
      end

      it 'succeeds when the source is valid' do
        xhr :post, url, url: source_url, format: :json
        expect(response).to be_jsend_success
        expect(response.jsend_data[:redirect]).to be
      end

      it 'fails when the source is invalid' do
        source.images.clear
        xhr :post, url, url: source_url, format: :json
        expect(response).to be_jsend_failure
        expect(response.jsend_data[:message]).to be
      end
    end

    it 'fails when the uri is bogus' do
      bogus_url = '!@#$@$@!$@!'
      ListingSource.expects(:scrape).with(bogus_url).raises(URI::InvalidURIError)
      xhr :post, url, url: bogus_url, format: :json
      expect(response).to be_jsend_failure
      expect(response.jsend_data[:message]).to be
    end

    it 'fails when there is an issue fetching the source page content' do
      ListingSource.expects(:scrape).with(source_url).raises(Faraday::Error::ResourceNotFound.new("Not found"))
      xhr :post, url, url: source_url, format: :json
      expect(response).to be_jsend_failure
      expect(response.jsend_data[:message]).to be
    end

    it 'errors when there is an unexpected exception' do
      ListingSource.expects(:scrape).with(source_url).raises('Boom')
      xhr :post, url, url: source_url, format: :json
      expect(response).to be_jsend_error
    end

    context 'and the source is from the bookmarklet' do
      let(:source) { FactoryGirl.build(:listing_source, url: source_url) }
      let(:base_params) {{
        url: source_url,
        price: '4.50',
        title: 'foobar',
      }}
      let(:image_params) { base_params.merge({
        images: {
          "http://copious.com/image.jpg" => { "width" => "500", "height" => "500" }
        }
      })}

      it 'succeeds when the source is valid' do
        xhr :post, url, image_params.merge(format: :json, source: :bookmarklet)
        expect(response).to be_jsend_success
        expect(response.jsend_data[:redirect]).to be
      end

      it 'fails when the source is invalid' do
        source.images.clear
        xhr :post, url, base_params.merge(format: :json, source: :bookmarklet)
        expect(response).to be_jsend_failure
        expect(response.jsend_data[:message]).to be
      end
    end
  end
end
