require 'spec_helper'

describe Users::Haves do
  let!(:user) { FactoryGirl.create(:registered_user) }
  let!(:item) { FactoryGirl.create(:item) }

  describe '.have_item!' do
    it 'returns the existing have without creating a new one' do
      FactoryGirl.create(:have, item: item, user: user)
      expect(user.has_item!(item)).to be
      expect(user.haves.size).to eq(1)
    end

    it 'returns a newly created have' do
      expect(user.has_item!(item)).to be
    end
  end

  describe '.has_item?' do
    it 'returns true when the user has the item' do
      FactoryGirl.create(:have, item: item, user: user)
      expect(user).to have_item(item)
    end

    it 'returns false when the user does not have the item' do
      expect(user).to_not have_item(item)
    end
  end

  describe '.have_for_item' do
    it 'returns the have when the user has the item' do
      FactoryGirl.create(:have, item: item, user: user)
      expect(user.have_for_item(item)).to be
    end

    it 'returns nil when the user does not have the item' do
      expect(user.have_for_item(item)).to be_nil
    end
  end
end
