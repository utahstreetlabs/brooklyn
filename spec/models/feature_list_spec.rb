require 'spec_helper'

describe FeatureList do
  it_should_behave_like "a sluggable model", :feature_list

  describe "finding or creating all new feature lists" do
    before do
      @names = ['post-metal', 'sludge metal', 'progressive rock']
      @feature_lists = FeatureList.find_or_create_all_by_name(@names)
    end

    it "returns every feature list" do
      @feature_lists.should have(@names.size).feature_lists
    end

    it "saves every feature list" do
      @feature_lists.each {|t| t.persisted?.should be_true}
    end
  end

  describe "finding or creating some new feature lists" do
    before do
      @names = ['post-metal', 'sludge metal', 'progressive rock']
      FactoryGirl.create(:feature_list, :name => @names.first)
      @feature_lists = FeatureList.find_or_create_all_by_name(@names)
    end

    it "returns every feature list" do
      @feature_lists.should have(@names.size).feature_lists
    end

    it "saves every feature list" do
      @feature_lists.each {|t| t.persisted?.should be_true}
    end

    it "doesn't create a feature list if its slug matches an existing feature list with a different name" do
      existing = FeatureList.find_by_slug('post-metal')
      feature_lists = FeatureList.find_or_create_all_by_name(['post metal'])
      feature_lists.first.should == existing
    end
  end

  describe '::find_listings_in_window' do
    let!(:feature_list) { FactoryGirl.create(:feature_list) }
    let(:earliest) { 5.days.ago }
    let(:latest) { 2.days.ago }
    let(:listing) { FactoryGirl.create(:active_listing) }

    it 'includes a feature created in the window' do
      feature = nil
      Timecop.travel(3.days.ago) do
        feature = FactoryGirl.create(:feature_list_feature, featurable: feature_list, listing: listing)
      end
      expect(feature_list.find_listings_in_window(earliest, latest)).to eq([listing])
    end

    it 'excludes a feature created too early' do
      Timecop.travel(10.days.ago) { FactoryGirl.create(:feature_list_feature, featurable: feature_list) }
      expect(feature_list.find_listings_in_window(earliest, latest)).to be_empty
    end

    it 'excludes a feature created too late' do
      FactoryGirl.create(:feature_list_feature, featurable: feature_list)
      expect(feature_list.find_listings_in_window(earliest, latest)).to be_empty
    end
  end

  describe '::find_recent_listings' do
    let!(:feature_list) { FactoryGirl.create(:feature_list) }
    let(:limit) { 2 }
    let(:listings) { FactoryGirl.create_list(:active_listing, 2 * limit) }
    let!(:features) do
      listings.each_with_index do |listing, i|
        Timecop.travel((100 - i).minutes.ago) do
          FactoryGirl.create(:feature_list_feature, featurable: feature_list, listing: listing)
        end
      end
    end

    it 'limits results and orders in reverse chron' do
      expect(feature_list.find_recent_listings(limit)).to eq(listings.reverse[0...limit])
    end
  end
end
