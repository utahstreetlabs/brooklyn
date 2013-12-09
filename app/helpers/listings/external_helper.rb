module Listings
  module ExternalHelper
    def external_listing_photo_selector(listing)
      images = listing.source.relevant_images(count: ListingSource.config.image_choice_count)
      selected_id = listing.source_image_id || images.first.id
      content_tag(:ul, class: 'photo-list') do
        out = []
        images.each do |image|
          li_classes = []
          li_classes << 'selected' if selected_id == image.id
          out << content_tag(:li, class: class_attribute(li_classes), data: {:'source-image' => image.id}) do
            content_tag(:div, class: 'photo-container') do
              image_tag(image.url, size: '108x108', alt: '', class: 'scraped-image')
            end
          end
        end
        safe_join(out)
      end
    end
  end
end
