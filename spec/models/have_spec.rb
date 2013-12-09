require 'spec_helper'

describe Have do
  describe 'after create' do
    it 'tracks an event' do
      have = FactoryGirl.build(:have)
      have.expects(:track_usage).with(is_a(Events::HaveItem))
      have.save!
    end
  end
end
