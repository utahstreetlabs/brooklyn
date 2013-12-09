require 'spec_helper'

describe TagCardHelper do
  describe '#tag_card' do
    let(:tag) { stub_tag 'mezcal' }
    let(:card) { stub('card', tag: tag, photos: []) }

    context 'when the user likes the tag' do
      before { card.stubs(:liked?).returns(true) }

      it 'shows the card in the liked state' do
        do_tag_card.should have_css('.tag-container.liked')
      end

      it 'shows the unlike button' do
        do_tag_card.should have_css('.button.inactive')
      end
    end

    context 'when the user does not like the tag' do
      before { card.stubs(:liked?).returns(false) }

      it 'shows the card in the not like state' do
        do_tag_card.should_not have_css('.tag-container.liked')
      end

      it 'shows the like button' do
        do_tag_card.should_not have_css('.button.liked')
      end
    end

    def do_tag_card
      helper.tag_card(card, like_path: '', unlike_path: '')
    end
  end
end
