require 'spec_helper'

describe ListingPhoto do
  let(:file) { stub('file') }
  let(:height) { 1 }
  let(:width) { 2 }
  let(:dimensions) { [height, width] }
  before { subject.stubs(:file).returns(file) }

  it "should return the dimensions of the underlying file" do
    should_calculate_and_cache_image_dimensions
  end

  context "when the listing photo is persisted" do
    subject { FactoryGirl.create(:listing_photo) }
    it "should return the dimensions of the underlying file when listing photo is persisted" do
      should_calculate_and_cache_image_dimensions
    end
  end

  def should_calculate_and_cache_image_dimensions
    file.expects(:calculate_geometry).returns(dimensions).once
    # do this twice - calculate geometry should only be called once
    2.times do
      subject.image_dimensions.should == dimensions
    end
  end
end
