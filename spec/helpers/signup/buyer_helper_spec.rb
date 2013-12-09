require 'spec_helper'

describe Signup::BuyerHelper do
  describe '#signup_buyer_interest_like_control' do
    let(:cards) { stub('interest-cards', liked: liked) }
    let(:liked) { num_liked.times.map {|n| stub("liked-card-#{n}")} }

    context 'when the user has liked enough interests' do
      let(:num_liked) { Interest.num_required_for_signup }

      it 'should enable the next button' do
        helper.signup_buyer_interest_like_control(cards).should_not have_css('.button.disabled')
      end

      it 'should hide the counter' do
        helper.signup_buyer_interest_like_control(cards).should have_css('.likes-counter.done')
      end

      it 'should set the counter to 0' do
        helper.signup_buyer_interest_like_control(cards).should have_content('0 more to go')
      end
    end

    context 'when the user has not liked enough tags' do
      let(:num_liked) { Interest.num_required_for_signup - 1 }

      it 'should disable the next button' do
        helper.signup_buyer_interest_like_control(cards).should have_css('.button.disabled')
      end

      it 'should show the counter' do
        helper.signup_buyer_interest_like_control(cards).should_not have_css('.likes-counter.done')
      end

      it 'should set the counter to the number of likes needed' do
        helper.signup_buyer_interest_like_control(cards).should have_content('1 more to go')
      end
    end
  end
end
