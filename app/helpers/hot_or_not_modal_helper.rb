module HotOrNotModalHelper
  def hot_or_not_modal(modal)
    bootstrap_modal('hot-or-not', nil, show_header: false, show_footer: false, never_close: true) do
      out = []
      out << content_tag(:h2, 'Discover lorem ipsum dolor sit amet')
      out << content_tag(:h3, 'Lorem ipsum dolor sit amet, consectetur adpiscing elit.')
      out << listing_photo_tag(modal.photo, :medium)
      out << listing_hot_button(modal.listing)
      out << listing_not_button(modal.listing)
      safe_join(out)
    end
  end

  def listing_hot_button(listing)
    bootstrap_button(listing_hotness_path(listing), data: {method: :post, action: :'listing-hot'}) do
      # XXX-hot-or-not: replace with images
      'Hot'
    end
  end

  def listing_not_button(listing)
    bootstrap_button(listing_hotness_path(listing), data: {method: :delete, action: :'listing-not'}) do
      # XXX-hot-or-not: replace with images
      'Not'
    end
  end
end
