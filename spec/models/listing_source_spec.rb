require 'spec_helper'

describe ListingSource do
  describe 'validation' do
    it 'fails when there are no images' do
      expect(subject).to_not be_valid
      expect(subject.errors[:images]).to have(1).error
    end

    it 'fails when there are no images that are large enough' do
      subject.images.build(FactoryGirl.attributes_for(:listing_source_image, height: 1, width: 1))
      subject.images.build(FactoryGirl.attributes_for(:listing_source_image, height: nil, width: nil, size: 1.byte))
      expect(subject).to_not be_valid
      expect(subject.errors[:images]).to have(1).error
    end

    it 'succeeds when there is an image with large enough area' do
      subject.images.build(FactoryGirl.attributes_for(:listing_source_image, height: 100, width: 100))
      expect(subject).to be_valid
    end

    it 'succeeds when there is an image with large enough size' do
      subject.images.build(FactoryGirl.attributes_for(:listing_source_image, height: nil, width: nil,
                                                      size: 25.kilobytes))
      expect(subject).to be_valid
    end
  end

  describe 'creation' do
    subject { FactoryGirl.create(:listing_source) }

    it 'creates a uuid' do
      expect(subject.uuid).to be
    end
  end

  describe '.build_from_bookmarklet' do
    let(:base_params) {{
      url: 'http://fnord.example.com',
      price: '4.50',
      title: 'foobar'
    }}
    let(:needs_escape_url) { 'http://fnord.example.com#thisIsATest.aspx|ofTheAmericanBroadcastingSystem' }

    context 'when url contains characters that need to be escaped' do
      it 'succeeds' do
        expect(ListingSource.build_from_bookmarklet(base_params.merge(url: needs_escape_url))).to be
      end
    end

    context 'when there is an image' do
      let(:params) { base_params.merge({
        images: {
          "http://copious.com/image.jpg" => { "width" => "500", "height" => "500" }
        }
      })}

      it 'succeeds' do
        expect(ListingSource.build_from_bookmarklet(params)).to be
      end

      it 'is valid' do
        expect(ListingSource.build_from_bookmarklet(params)).to be_valid
      end

      context 'when url contains characters that need to be escaped' do
        it 'is valid' do
          expect(ListingSource.build_from_bookmarklet(params.merge(url: needs_escape_url))).to be
        end
      end
    end

    context 'when there are no images' do
      it 'is not valid' do
        expect(ListingSource.build_from_bookmarklet(base_params)).to_not be_valid
      end
    end
  end

  describe '.relevant_images' do
    it 'returns largest image first' do
      image1 = subject.images.build(height: 250, width: 250)
      image2 = subject.images.build(height: 500, width: 500)
      expect(subject.relevant_images).to eq([image2, image1])
    end

    it 'returns images with dimensions before images with sizes' do
      image1 = subject.images.build(height: 250, width: 250)
      image2 = subject.images.build(height: 500, width: 500)
      image3 = subject.images.build(height: nil, width: nil, size: 8.kilobytes)
      image4 = subject.images.build(height: nil, width: nil, size: 20.kilobytes)
      expect(subject.relevant_images).to eq([image2, image1, image4, image3])
    end

    it 'omits images whose areas are too small' do
      image1 = subject.images.build(height: 75, width: 75)
      image2 = subject.images.build(height: 250, width: 250)
      expect(subject.relevant_images).to eq([image2])
    end

    it 'omits images whose sizes are too small' do
      image1 = subject.images.build(height: nil, width: nil, size: 20.kilobytes)
      image2 = subject.images.build(height: nil, width: nil, size: 5.kilobytes)
      expect(subject.relevant_images).to eq([image1])
    end
  end

  describe '.domain' do
    it 'returns the second level domain of the url' do
      subject.url = 'http://fnord.example.com/foo/bar'
      expect(subject.domain).to eq('example.com')
    end
  end
end

describe ListingSource::Scraper do
  let(:page_url) { 'http://example.com/thinger' }
  let(:image1_url) { 'http://example.com/img1.jpg' }
  let(:image2_url) { 'http://example.com/img2.jpg' }
  let(:og_image_url) { 'http://example.com/primary.jpg' }
  let(:response) do
    stub('response', headers: {'Content-Type' => 'text/html;charset=UTF-8'}, body: <<-EOT
<html>
  <head>
    <title>A Thinger</title>
    <meta property="og:image" content="#{og_image_url}">
  </head>
  <body>
  <script type="text/javascript">
    var $wrongPrice = '$50.00';
  </script>
  <p>This thinger costs $25.00 and shipping is free!</p>
  <img src="#{image1_url}" height="250">
  <img src="#{image2_url}">
  </body>
</html>
EOT
    )
  end
  before do
    ListingSource::Scraper::Fetcher.any_instance.stubs(:fetch).with(URI(page_url)).returns(response)
  end

  subject { ListingSource::Scraper.new(page_url) }

  describe '.initialize' do
    it 'adds a scheme and slashes to a bare url' do
      expect(ListingSource::Scraper.new('example.com/foo').url).to eq('http://example.com/foo')
    end

    it 'adds a scheme but no slashes to a // url' do
      expect(ListingSource::Scraper.new('//example.com/foo').url).to eq('http://example.com/foo')
    end

    it 'does not add a scheme to http url' do
      expect(ListingSource::Scraper.new('http://example.com/foo').url).to eq('http://example.com/foo')
    end

    it 'does not add a scheme to https url' do
      expect(ListingSource::Scraper.new('https://example.com/foo').url).to eq('https://example.com/foo')
    end

    context "when the url contains characters that need escaping" do
      it 'succeeds' do
        expect(ListingSource::Scraper.new('https://example.com/foo#bar|baz').url).to eq('https://example.com/foo#bar%7Cbaz')
      end
    end
  end

  it 'scrapes the title' do
    expect(subject.title).to eq('A Thinger')
  end

  it 'scrapes the open graph image' do
    expect(subject.open_graph_image).to be
  end

  it 'scrapes the images' do
    expect(subject.images).to have(2).images
  end

  it 'scrapes the price, ignoring scripts' do
    expect(subject.price).to eq(25.00)
  end

  it 'blows up when the resource is not of an acceptable media type' do
    response.headers['Content-Type'] = 'image/png'
    expect { subject.content }.to raise_error(ListingSource::Scraper::UnacceptableMediaType)
  end
end

describe ListingSource::Scraper::Img do
  describe '.uri' do
    subject { ListingSource::Scraper::Img.new(node, base_uri, fetcher) }
    let(:base_uri) { URI('http://example.com') }
    let(:fetcher) { stub('fetcher') }

    context 'for a content url' do
      let(:node) { {'content' => 'http://example.com/foo.jpg'} }

      it 'leaves it alone' do
        expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
      end
    end

    context 'for a perfectly formed url' do
      let(:node) { {'src' => 'http://example.com/foo.jpg'} }

      it 'leaves it alone' do
        expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
      end
    end

    context 'for a url that needs escaping' do
      let(:node) { {'src' => 'http://example.com#foo.jpg|testing' } }

      it 'escapes the url' do
        expect(subject.uri).to eq(URI('http://example.com#foo.jpg%7Ctesting'))
      end
    end

    context 'for a // url' do
      let(:node) { {'src' => '//example.com/foo.jpg'} }

      it 'adds a scheme but no slashes' do
        expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
      end
    end

    context 'for a root-relative url' do
      let(:node) { {'src' => '/foo.jpg'} }

      it 'absolutizes it' do
        expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
      end
    end

    context 'for a relative url' do
      let(:node) { {'src' => 'foo.jpg'} }

      context 'when base url has a path ending in /' do
        let(:base_uri) { URI('http://example.com/bar/') }

        it 'absolutizes it relative to base path' do
          expect(subject.uri).to eq(URI('http://example.com/bar/foo.jpg'))
        end
      end

      context 'when base url has a path not ending in /' do
        let(:base_uri) { URI('http://example.com/bar') }

        it 'absolutizes it relative to parent segment of base path' do
          expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
        end
      end

      context 'when base url does not have a path' do
        it 'absolutizes it relative to root' do
          expect(subject.uri).to eq(URI('http://example.com/foo.jpg'))
        end
      end
    end
  end

  describe '.determine_dimensions' do
    subject { ListingSource::Scraper::Img.new(node, base_uri, fetcher) }
    let(:base_uri) { URI('http://example.com') }
    let(:fetcher) { stub('fetcher') }

    context 'when height attr is specified' do
      let(:node) { {'height' => 250} }

      it 'returns height only' do
        expect(subject.determine_dimensions).to eq([250, nil])
      end
    end

    context 'when width attr is specified' do
      let(:node) { {'width' => 93} }

      it 'returns width only' do
        expect(subject.determine_dimensions).to eq([nil, 93])
      end
    end

    context 'when height and width attrs are specified' do
      let(:node) { {'height' => 250, 'width' => 93} }

      it 'returns height and width' do
        expect(subject.determine_dimensions).to eq([250, 93])
      end
    end

    context 'when height style is specified' do
      let(:node) { {'style' => 'height:250px'} }

      it 'returns height only' do
        expect(subject.determine_dimensions).to eq([250, nil])
      end
    end

    context 'when width style is specified' do
      let(:node) { {'style' => 'width:93px'} }

      it 'returns width only' do
        expect(subject.determine_dimensions).to eq([nil, 93])
      end
    end

    context 'when height and width styles are specified' do
      let(:node) { {'style' => 'height:250px;width:93px'} }

      it 'returns height and width' do
        expect(subject.determine_dimensions).to eq([250, 93])
      end
    end

    context 'when no data is specified' do
      let(:node) { {} }

      it 'returns nothing' do
        expect(subject.determine_dimensions).to eq([nil, nil])
      end
    end
  end

  describe '.size' do
    subject { ListingSource::Scraper::Img.new(node, base_uri, fetcher) }
    let(:base_uri) { URI('http://example.com') }
    let(:fetcher) { stub('fetcher') }
    let(:node) { {'content' => image_uri.to_s} }
    let(:image_uri) { URI('http://example.com/foo.jpg') }
    let(:size) { 12345 }

    context "when the fetcher finds an image size" do
      before do
        response = stub('response', headers: {'Content-Length' => size.to_s})
        fetcher.expects(:fetch).with(image_uri, has_entry(method: :head)).returns(response)
      end

      it 'returns the size as a number' do
        expect(subject.size).to eq(size)
      end
    end

    context "when the fetcher does not find an image size" do
      before do
        response = stub('response', headers: {})
        fetcher.expects(:fetch).with(image_uri, has_entry(method: :head)).returns(response)
      end

      it 'returns nil' do
        expect(subject.size).to be_nil
      end
    end
  end
end
