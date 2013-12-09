require 'spec_helper'

describe UserInterest do
  context '#after_create' do
    let(:autofollow_count) { Brooklyn::Application.config.collections.autofollow.per_interest }
    let!(:user) { FactoryGirl.create(:registered_user) }
    let!(:interest) { FactoryGirl.create(:interest) }
    let(:collection_owner) { FactoryGirl.create(:registered_user) }
    let!(:collections) { FactoryGirl.create_list(:collection, 2 * autofollow_count, user: collection_owner) }

    before do
      collections.each { |c| FactoryGirl.create(:collection_autofollow, collection: c, interest: interest) }
      user.add_interest_in!(interest)
    end

    it 'auto follows a random selection of collections based on a user adding an interest' do
      expect(user.unowned_collection_follows_count).to eq(autofollow_count)
    end
  end
end
