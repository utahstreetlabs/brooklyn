# helpers for generating connection digest emails
module ConnectionDigestHelper
  def cdigest_listing_details(listing)
    title_style = "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 15px; font-weight: 300; line-height: 20px; color: #009AAF; display: block; text-align: left; width: 252px; min-height: 20px; max-height: 40px; overflow: hidden; margin-top: 4px; margin-bottom: 5px;"
    price_style = "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 15px; font-weight: 400; line-height: 15px; color: #43C843; display: inline-block; text-align: left; max-width: 150px; margin-top: 9px; float: left;"

    content_tag(:span, listing.title, :class => 'product-title', style: title_style) +
      content_tag(:span, smart_number_to_currency(listing.price), :class => 'product-price', style: price_style)
  end

  def cdigest_listing(listing, like_count)
    url = listing_url(listing)
    style = 'width: 50%; max-width: 280px; margin-right: 0px; float: left; margin-bottom: 30px;'
    image_style = "width: 250px !important; height: 250px !important; border-width: 1px; border-style: solid; border-color: #BBBBBB; margin: 0px; padding: 2px; background-color: white;"
    seller = listing.seller
    seller_info = "width: 256px; height: 350px; margin-top: 0px; margin-bottom: 3px; margin-left: auto; margin-right: auto;"
    seller_image_style = "width: 20px; height: 20px; border-width: 1px; border-style: solid; border-color: #BBBBBB; float: left;"
    seller_name_style = "font-size: 15px; line-height: 23px; font-weight: 300; font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; color: #009AAF !important; text-align: left; width: 220px; margin-top: 2px; margin-bottom: 0px;float:left; text-decoration: none"
    seller_link_style = "padding-top: 1px; padding-right: 1px; padding-bottom: 1px; padding-left: 1px; margin-right: 8px; margin-bottom: 5px; float: left;border-width: 1px; border-style: solid; border-color: #CCCCCC; line-height: 0px;"
    content_tag :div, title: listing.title, :class => 'cards', style: style do
      content_tag :div, title: listing.title, :class => 'seller_info', style: seller_info do
        out = []
        out << mailer_link_to(mailer_image_tag(seller.profile_photo.url("px_30x30"), style: seller_image_style, :class => "seller-avatar-img"),
                              public_profile_url(seller), :class =>"seller-avatar", style: seller_link_style)
        out << content_tag(:h2, mailer_link_to(seller.name, public_profile_url(seller), :class => "seller-name", style: seller_name_style))
        out << mailer_link_to(mailer_image_tag(listing.photos.first.version_url(:medium), style: image_style), url)
        out << mailer_link_to(cdigest_listing_details(listing), url, style: "text-decoration: none !important;")
        out << responsive_mailer_button(image_tag('http://assets.copious.com/images/copious-weekly-digest/CWD-love.png')+"#{like_count} Love", like_listing_url(listing), :class => 'love')
        safe_join(out, "\n")
      end
    end
  end

  def cdigest_listings(listings, like_counts)
    listings.each_slice(2).map do |(first, second)|
      cdigest_listing(first, like_counts[first.id]) + "\n" +
        (second ? cdigest_listing(second, like_counts[second.id]) : '')
    end
  end

  def cdigest_user_profile(user_strip, recipient)
    user = user_strip.user
    image_style = "width: 30px; height: 30px; border-width: 1px; border-style: solid; border-color: #BBBBBB; float: left;"
    name_style = "font-size: 16px; line-height: 23px; font-weight: 300; font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; color: #009AAF !important; text-align: left; width: 221px; margin-top: 6px; margin-bottom: 0px;float:left;"
    link_style = "padding-top: 1px; padding-right: 1px; padding-bottom: 1px; padding-left: 1px; margin-right: 10px; float: left;border-width: 1px; border-style: solid; border-color: #CCCCCC; line-height: 0px;"

    out = []
    out << mailer_link_to(mailer_image_tag(user.profile_photo.url("px_50x50"), style: image_style),
                          public_profile_url(user), :class =>"seller-avatar", style: link_style)
    out << content_tag(:h2, user.name, :class => "seller-name", style: name_style)
    out << responsive_mailer_button( "Follow", public_profile_follow_url(user), :class => 'seller-profile-follow') unless user_strip.viewer_following
    safe_join(out, "\n")
  end

  def cdigest_user_thumbs(user_strip)
    image_style = "width: 120px; border-width: 1px; border-style: solid; border-color: #BBBBBB;"
    link_style = "padding-top: 2px; padding-right: 2px; padding-bottom: 2px; padding-left: 2px; margin-right: 6px; float: left;border-width: 1px; border-style: solid; border-color: #BBBBBB; line-height: 0px;"

    if user_strip.listings.first
      listings = user_strip.listings.map(&:first)
      listings.map do |listing|
        link_class = cycle('seller-thumbnail', 'seller-thumbnail-even')
        link_style = link_style + (listing == listings.last ? 'margin-right: 0px' : '')
        mailer_link_to(mailer_image_tag(listing.photos.first.version_url(:medium), :class => 'seller-thumbnail-image', style: image_style),
                       listing_url(listing), :class => link_class, style: link_style)
      end.join("\n").html_safe
    end
  end

  def cdigest_user_strip(user_strip, recipient)
    container_style = "width: 530px; margin-top: 0px; margin-bottom: 16px; margin-left: auto; margin-right: auto; text-align: center;"
    profile_style = "width: 100%; margin-right: 0px; float: left; margin-bottom: 7px;"
    thumbnail_style = "width: 530px; margin-bottom: 16px; margin-top: 0px; margin-left: auto; margin-right: auto;"

    content_tag :div, :class => 'seller-container', style: container_style do
      content_tag(:div, cdigest_user_profile(user_strip, recipient), :class => "seller-profile-header", style: profile_style) +
        content_tag(:div, cdigest_user_thumbs(user_strip), :class => "seller-thumbnail-container", style: thumbnail_style)
    end
  end

  def cdigest_user_strips(user_strips)
    user_strips.map do |user_strip|
      cdigest_user_strip(user_strip, user_strips.viewer)
    end
  end

  def cdigest_email_settings
    "To disable digest emails from Copious, #{mailer_link_to 'click here', settings_email_url}."
  end

  def connection_digest_content(listings, like_counts, suggestion_strips)
    content = [[responsive_header('Most popular listings from your feed')] + cdigest_listings(listings, like_counts)]
    content << [responsive_header('Popular users in your network')] + cdigest_user_strips(suggestion_strips) unless suggestion_strips.users.empty?
    content
  end
end
