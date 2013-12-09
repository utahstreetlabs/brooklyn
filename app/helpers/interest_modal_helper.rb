module InterestModalHelper
  def select_interests_button
    bootstrap_button(t('home.feed.select_interests.button.label'), type: :button, toggle_modal: 'select-interests', condition: :primary, action_type: :curatorial)
  end

  def select_interests_modal
    bootstrap_modal('select-interests', t('home.feed.select_interests.modal.title'),
                    data: {url: signup_buyer_interests_path, role: 'interests-modal',
                           build_feed_url: signup_buyer_feed_build_path},
                    show_close: false, save_button_text: t('home.feed.select_interests.modal.save.label')) do

    end
  end

  def select_interests_modal_content(interest_cards)
    out = []
    out << content_tag(:p) do
      t('home.feed.select_interests.modal.description')
    end
    out << content_tag(:div, class: 'interest-card-container') do
      signup_interests(interest_cards)
    end
    out << select_interests_counter
    safe_join(out)
  end

  def select_interests_counter
    content_tag(:div, class: 'modal-checkbox-cta') do
      cta_options = {data: {role: 'counter-cta'}}
      cta_options[:style] = 'display: none' if current_user.interests_remaining_count == 0
      content_tag(:div, cta_options) do
        t('home.feed.select_interests.modal.counter_html', count: current_user.interests_remaining_count)
      end
    end
  end

  def signup_interests(interest_cards)
    cards = interest_cards.each_with_index.map do |card, i|
      interest_card(card, like_path: signup_buyer_interest_like_path(card.interest, l: (i+1)),
                    unlike_path: signup_buyer_interest_unlike_path(card.interest, l: (i+1)))
    end
    safe_join(cards)
  end

  def select_interests_button_and_modal
    out = []
    out << select_interests_button
    out << select_interests_modal
    safe_join(out)
  end
end
