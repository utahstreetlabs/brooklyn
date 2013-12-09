require 'spec_helper'

describe InterestCardHelper do
  describe '#interest_card' do
    let(:cover_photo) { fixture_file_upload('/hamburgler.jpg', 'image/jpg') }
    let(:interest) { FactoryGirl.create(:interest, {name: "hamburgler", onboarding: '1', cover_photo: cover_photo}) }
    let(:card) { stub('card', interest: interest, photos: []) }

    context 'when the user likes the interest' do
      before { card.stubs(:liked?).returns(true) }

      it 'shows the card in the liked state' do
        do_interest_card.should have_css('.selected')
      end

      it 'shows the unlike button' do
        do_interest_card.should have_css('.selected')
      end
    end

    context 'when the user does not like the interest' do
      before { card.stubs(:liked?).returns(false) }

      it 'shows the card in the not like state' do
        do_interest_card.should_not have_css('.selected')
      end

      it 'shows the like button' do
        do_interest_card.should_not have_css('.selected')
      end
    end

    def do_interest_card
      interest.expects(:cover_photo).returns(interest.cover_photo).at_least_once
      helper.interest_card(card, like_path: '', unlike_path: '')
    end
  end
end
