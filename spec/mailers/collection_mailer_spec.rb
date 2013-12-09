require 'spec_helper'

describe CollectionMailer do
  let!(:collection) { FactoryGirl.create(:collection) }
  let!(:follower) { FactoryGirl.create(:registered_user) }

  context "when the collection is not empty" do
    before do
      collection.add_listing(FactoryGirl.create(:active_listing))
    end

    it "builds a followed message" do
      expect { CollectionMailer.collection_follow(collection, follower.id) }.to_not raise_error
    end
  end

  context "when the collection is empty" do
    it "builds a followed message" do
      expect { CollectionMailer.collection_follow(collection, follower.id) }.to_not raise_error
    end
  end
end
