module OffersHelper
  def offer_body_class(offer)
    body_classes = %w(offers_show_1)
    body_classes += Array.wrap(Brooklyn::Application.config.offers.custom_body_classes[offer.uuid]).compact.uniq
    body_class(class_attribute(body_classes))
  end

  def offer_body_style(offer)
    if offer_full_screen_background?(offer)
      body_style("background: url('#{offer_background_image(offer)}') no-repeat top center fixed")
    else
      body_style("background-image: url('#{offer_background_image(offer)}')")
    end
  end

  def offer_full_screen_background?(offer)
    @offer.uuid.in?(Brooklyn::Application.config.offers.full_screen_background)
  end

  def offer_background_image(offer)
    url = offer.landing_page_background_photo.present? ? offer.landing_page_background_photo :
      'landing/seller/seller-offer-bg.jpg'
    image_path(url)
  end

  def offer_headline(offer)
    offer.landing_page_headline.present? ? offer.landing_page_headline :
      t('.headline')
  end

  def offer_text(offer)
    text = if offer.landing_page_text.present?
      offer.landing_page_text.
        gsub(/%{sellers}/, seller_name_list(offer.sellers)).
        gsub(/%{amount}/, %Q[<span class="incentive-dollars">#{number_to_currency(offer.amount)}</span>])
    elsif offer.sellers.any?
      t('.text.with_sellers_html', amount: number_to_currency(offer.amount), sellers: seller_name_list(offer.sellers))
    else
      t('.text.without_sellers_html', amount: number_to_currency(offer.amount))
    end
    raw(text)
  end

  def seller_name_list(sellers)
    sellers.map { |s| s.name }.to_sentence
  end

  def formatted_offer_duration(offer)
    distance_of_time_in_words(0, offer.duration * 60)
  end

  def signup_offer
    Offer.signup_offer
  end

  def formatted_expiry_date(offer)
    if offer.expires_at
      (offer.expires_at - 1.day).strftime('%A')
    else
      'Never'
    end
  end

  def number_to_offer_currency(amount)
    number_to_currency(amount, precision: 0)
  end

  def formatted_user_types(offer)
    if offer.new_users?
      if offer.existing_users?
        "Verified accounts only"
      else
        "Verified, new accounts only"
      end
    else
      "Verified, existing accounts only"
    end
  end
end
