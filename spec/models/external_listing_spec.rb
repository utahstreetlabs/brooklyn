require 'spec_helper'

describe ExternalListing do
  describe 'validation' do
    context 'of a new record' do
      it 'fails without a source image' do
        expect(subject).to_not be_valid
        expect(subject.errors[:source_image_id]).to have(1).error
      end

      it 'succeeds with all required data' do
        subject.source = FactoryGirl.create(:listing_source)
        subject.source_image = subject.source.images.first
        subject.title = 'Vintage Wilco "Yankee Hotel Foxtrot" vinyl, original pressing'
        subject.price = 100.00
        subject.description = "Great record."
        expect(subject).to be_valid
      end
    end

    context 'of an existing record' do
      subject { FactoryGirl.create(:external_listing) }

      it 'succeeds without a source image' do
        subject.source_image = nil
        expect(subject).to be_valid
      end

      it 'succeeds without an initial comment' do
        subject.initial_comment = nil
        expect(subject).to be_valid
      end
    end
  end

  describe 'creation' do
    before do
      subject.source = FactoryGirl.create(:listing_source)
      subject.source_image = subject.source.images.first
      subject.title = 'Wrap It Up Box'
      subject.price = 299.99
      subject.category = FactoryGirl.create(:category)
      subject.description = 'Comedy gold or a really good idea?'
      subject.seller = FactoryGirl.create(:registered_user)
      subject.save!
    end

    it 'uses the source image for the primary photo' do
      source_file = File.new(subject.source_image.url)
      photo_file = File.new(subject.photos.first.file.current_path)
      expect(FileUtils.compare_file(source_file, photo_file)).to be_true
    end

    it 'activates the listing' do
      expect(subject).to be_active
    end
  end
end
