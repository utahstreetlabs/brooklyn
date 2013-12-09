require 'spec_helper'

describe Users::Wants do
  let!(:user) { FactoryGirl.create(:registered_user) }
  let!(:item) { FactoryGirl.create(:item) }
  let(:max_price) { 25.00.to_d }

  describe '.wants_item!' do
    it 'returns a newly created want' do
      expect(user.wants_item!(item, max_price: max_price)).to be
    end
  end

  describe '.wants_item?' do
    it 'returns true when the user wants the item' do
      FactoryGirl.create(:want, item: item, user: user)
      expect(user.wants_item?(item)).to be_true
    end

    it 'returns false when the user does not want the item' do
      expect(user.wants_item?(item)).to be_false
    end
  end

  describe '.want_for_item' do
    it 'returns the want when the user wants the item' do
      FactoryGirl.create(:want, item: item, user: user)
      expect(user.want_for_item(item)).to be
    end

    it 'returns nil when the user does not want the item' do
      expect(user.want_for_item(item)).to be_nil
    end
  end
end
