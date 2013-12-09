# encoding: utf-8
require 'progress_bar_helper'

module ListingsHelper
  include ProgressBarHelper
  include Brooklyn::Urls::ClassMethods

  ORDER_STEPS = {
    :confirmed => 'Purchase confirmed',
    :shipped => 'Shipped',
    :delivered => 'Delivered',
    :complete => 'Order complete' # XXX: account for settled
  }

  RETURN_STEPS = {
    :confirmed => 'Return confirmed',
    :shipped => 'Shipped',
    :delivered => 'Delivered',
    :complete => 'Return complete'
  }

  def return_progress_bar(listing)
    progress_bar(RETURN_STEPS, listing.order.status.to_sym)
  end

  def listing_order_progress_bar(listing)
    step = listing.order.status.to_sym
    progress_bar(ORDER_STEPS, step)
  end

  def listing_buyer_privacy(listing)
    content_tag(:div, class: 'pull-right margin-bottom buyer-privacy') do
      listing_order_privacy_control(listing) + order_privacy_hint
    end
  end

  def listing_order_privacy_control(listing)
    bootstrap_button_group(class: 'buttons privacy-toggle pull-right kill-margin', toggle: :radio,
        data: {role: :'buyer-privacy'}) do
      bootstrap_button(t('listings.order_details.public'), public_listing_path(listing),
        active: listing.order.public?, class: 'button', remote: true, method: :post,
        data: {link: :remote, action: :public}) +
      bootstrap_button(t('listings.order_details.private'), private_listing_path(listing),
        active: listing.order.private?, class: 'button', remote: true, method: :post,
        data: {link: :remote, action: :private})
    end
  end

  def postal_address(address, options = {})
    out = []
    if options[:name] == true
      out << content_tag(:span, address.name, class: 'ship-to-name', data: {role: 'postal-address'})
    end
    out << address.line1
    out << tag(:br)
    if address.line2.present?
      out << address.line2
      out << tag(:br)
    end
    out << "#{address.city}, #{address.state} #{address.zip}"
    out << tag(:br)
    out << address.phone
    out.join("\n").html_safe
  end

  def categories_select
    select_tag(:category, category_options_for_select, :include_blank => 'choose a category')
  end

  def category_options_for_select
    options_from_collection_for_select(Category.order_by_name, 'slug', 'name')
  end

  # generate select options appropriate for the listing form
  # @param Tag (Size or Brand) attribute The currently assigned size or brand to be pre-selected in the list
  # @param symbol key A symbol representing the type of tag (:b for brand, :s for size) so the most popular can be
  #                   fetched
  def options_for_combo(attribute, key)
    options = ["<option value=''></option>".html_safe]
    if attribute
      options << "<option value='#{ attribute.slug }' selected='selected'>#{ attribute.name }</option>".html_safe
    end

    Tag.find_popular(key).each do |i|
      options << "<option value='#{i[:slug]}'>#{i[:name]}</option>".html_safe
    end

    safe_join(options)
  end

  def brand_options_for_select(listing)
    options_for_combo(listing.brand, :b)
  end

  def size_options_for_select(listing)
    options_for_combo(listing.size, :s)
  end

  def listing_dimensions(listing)
    listing.category.dimensions.includes(:values).all
  end

  def dimension_label(text, dimension)
    label_tag("listing_dimensions_#{dimension.slug}", t("listings.category_dependent_fields.html.condition.label"), :required => false, :class => 'big-label')
  end

  def dimension_select(dimension, selected = nil, options = {})
    options[:id] = "listing_dimensions_#{dimension.slug}"
    select_tag("listing[dimensions][#{dimension.slug}]", dimension_value_options_for_select(dimension, selected),
               options)
  end

  def dimension_value_options_for_select(dimension, selected=nil)
    container = dimension.values.all.map{|x| [x.value, x.id]}
    container.unshift(disabled_options)
    options_for_select(container, selected)
  end

  def category_condition_select
    select_tag("listing[dimensions][condition]", options_for_select(disabled_options), class: 'span6', disabled: 'disabled')
  end

  def category_dimensions
    category_dimensions = {}

    DimensionValue.includes(:dimension).each do |i|
      category_dimensions[i.dimension.category_id] = [] if category_dimensions[i.dimension.category_id].nil?
      category_dimensions[i.dimension.category_id] << [i.id, i.value]
    end

    content_tag(:div, category_dimensions.to_json, class: 'hidden', id: 'categoryConditions')
  end

  def disabled_options
    [t("listings.category_dependent_fields.html.condition.blank_html"), nil]
  end

  def listing_dimension_value(listing, dimension)
    dv = @listing.dimension_value_for(dimension)
    dv ? dv.value : 'unspecified'
  end

  def listing_photo_tag(photo, version, options = {})
    image_tag(photo.file.send(version).url, {:alt => ''}.merge(options)) if photo
  end

  # @option options [String] :text the text of the link, if a block is not provided
  # @option options [Integer] :truncate if present, the length to which the listing title should be truncated
  # @option options [Hash] :url a hash of options to pass to +url_for+ when generating the link url
  def link_to_listing(listing, options = {}, &block)
    options = options.dup
    text = block.call if block_given?
    text ||= options.delete(:text)
    text ||= listing.title.present? ? listing.title : 'Draft Listing'
    truncate_length = options.delete(:truncate)
    text = truncate(text, length: truncate_length) if truncate_length
    if listing.cancelled?
      content_tag(:span, text, class: 'cancelled-listing')
    else
      options[:data] ||= {}
      options[:data][:action] ||= 'view-listing'
      url_options = options.delete(:url) || {}
      link_to(text, listing_path(listing, url_options), options)
    end
  end

  def link_to_delete_listing_photo(listing, photo)
    # This link is an image sprite, that's why it's blank.
    link_to '', listing_photo_path(listing, photo),
      confirm: 'Are you sure you want to remove this photo from your listing?', class: 'btn-delete btn-overlay',
      :'data-remote' => true, :'data-method' => :DELETE, :'data-type' => :json
  end

  def link_to_edit_listing_photo(text, listing, photo)
    link_to text, nilhref, data_attrs('photo-id' =>  "thumbnail-#{photo.id}",
      'photo-url' => "http:#{photo.file.url}", 'listing-id' => listing.id,
      'update-form-id' => "replace-thumbnail-#{photo.id}").merge(class: 'aviary-trigger button small button-block')
  end

  def link_to_import_photos_computer(text, form)
    content_tag :div, class: 'fileupload upload-computer-wrapper' do
      link_to(text, nilhref, class: 'button large') +
        form.file_field('file', multiple: true, class: 'upload-computer', id: 'upload-computer', accept: 'image/*')
    end
  end

  def link_to_add_photo_button(form)
    # file upload overlay technique from http://christorian.com/articles/How-to-make-your-own-browse-button/
    # be sure to do heavy cross browser testing when changing - file inputs are slippery beasts!
    content_tag :div, class: 'fileupload' do
      content_tag :li, class: 'btn-photo upload' do
        content_tag(:div, '', class: 'btn-upload') +
          content_tag(:div, class: 'file-input-wrapper') do
            form.file_field 'file', multiple: true, class: 'upload-computer'
          end
      end
    end
  end

  def share_listing_button(listing, network, text, options = {})
    url = if network == :pinterest
      # don't add class: 'pin-it-button' or count-layout to the link - we're using our own layout for the pin it
      # button rather than theirs
      pin_listing_photo_url(listing)
    else
      share_listing_path(listing, network)
    end
    link_to(image_and_text("social_networks/#{network}-share.png", text), url, options)
  end

  def pin_listing_photo_url(listing, photo = nil)
    photo ||= listing.photos.first
    qs = as_query_string(url: listing_url(listing), media: absolute_url(photo.file.large.url),
      description: "#{listing.title} #{number_to_currency(listing.price.to_s)}")
    "http://pinterest.com/pin/create/button/?#{qs}"
  end

  def listing_state_action_buttons(listing)
    out = []
    case listing.state
    when 'inactive'
      if guest?
        out << link_to_facebook_connect(label:'Sign Up & Publish My Listing', cl: 'primary button positive large signup facebook',
                 seller_signup: true)
        out << link_to_twitter_connect(label:'Sign Up & Publish My Listing', class: 'button margin-left',
                          seller_signup: true)
      else
        out << button_to('Publish My Listing', activate_listing_path(listing),
                 class: 'primary button left large', method: :POST, disable_with: 'Submitting...')
        out << link_to('Edit Listing', edit_listing_path(listing), class: 'button soft left large')
      end
    when 'active'
      out << link_to('Create Another Listing', listings_path, class: 'primary button positive large left', method: :POST)
      out << link_to('Go to Dashboard', dashboard_path, class: 'button positive left soft large')
    end
    out.join("\n").html_safe
  end

  def seller_info_cta_buttons(seller)
    link_to(t('.button.create_merchant_account'),  settings_seller_accounts_path, class: 'primary button left large')
  end

  def listing_trackers(listing)
    if display_requested?(:listing_purchase_trackers)
      adroll_track('success', conversion_value: listing.total_price, order_id: listing.order.reference_number)
      adwords_tracking_pixel(:purchase_complete, listing.total_price)
      ga_view_event('listings', 'buy')
    end
  end

  def share_listing_to_network(listing, network, options = {})
    network_name = t("networks.#{network}.name")
    link_class = options[:class] ? options[:class] + ' social-action' : 'social-action'
    options.merge!(target: :_blank, title: "Share on #{network_name}", 'data-network' => network,
                   'data-social-action' => share_action(network), class: link_class)
    text = translate(network, scope: [:listings, :share, :link, options[:text] || :default])
    content_tag :div, id: "share-listing-#{network}", class: 'share-listing' do
      share_listing_button(listing, network, text, options)
    end
  end

  NETWORK_ACTIONS = {facebook: :share, twitter: :tweet, tumblr: :post, pinterest: :pin}
  def share_action(network)
    NETWORK_ACTIONS[network]
  end

  def listing_comment_flag_reason_select_tag(name, selected_option = nil)
    option_tags = options_for_select [['Spam', :spam], ['Offensive', :offensive], ['Bullying', :bullying],
      ['Community Lamer', :lamer], ['Other Reason', :other]]
    select_tag name, options_for_select(option_tags, selected_option)
  end

  def link_to_flag_comment(comment, viewer)
    unless comment.flagged_by?(viewer.id)
      type = comment_type(comment)
      link_to(image_tag('icons/flag-grey.png'), '#', id: "listing-feed-#{type}-flag-#{comment.id}",
        class: "listing-feed-#{type}-flag") + spacer(' –')
    end
  end

  def link_to_reply_to_comment(comment)
    comment_id = is_reply?(comment) ? comment.parent_id : comment.id
    link_to('Reply', '#', id: "listing-feed-comment-reply-#{comment_id}", class: 'listing-feed-comment-reply') +
      spacer(' –')
  end

  def link_to_delete_comment(listing, comment)
    type = comment_type(comment)
    url = type == :reply ? listing_comment_reply_path(listing, comment.parent_id, comment) :
      listing_comment_path(listing, comment)
    link_to('Delete Comment', url, class: "button admin positive listing-feed-#{type}-action",
            data: {remote: true, method: :delete, type: :json}, rel: :nofollow)
  end

  def link_to_unflag_comment(listing, comment)
    if comment.flagged?
      type = comment_type(comment)
      url = type == :reply ? listing_comment_reply_unflag_path(listing, comment.parent_id, comment) :
        listing_comment_unflag_path(listing, comment)
      link_to('Unflag Comment', url, class: "listing-feed-#{type}-action",
              data: {remote: true, method: :delete, type: :json}, rel: :nofollow)
    end
  end

  def link_to_resend_comment_email(listing, comment)
    type = comment_type(comment)
    url = type == :reply ? listing_comment_reply_resend_email_path(listing, comment.parent_id, comment) :
      listing_comment_resend_email_path(listing, comment)
    link_to('Resend Email', url, class: "listing-feed-#{type}-action",
            data: {remote: true, method: :post, type: :json, action: "resend-#{type}-email"}, rel: :nofollow)
  end

  def listing_comment_flag_tray(comment, viewer)
    unless comment.flagged_by?(viewer.id)
      content_tag(:div, '', class: "listing-feed-#{comment_type(comment)}-flag-tray")
    end
  end

  def listing_comment_reply_tray(comment)
    unless is_reply?(comment)
      content_tag(:div, '', class: "listing-feed-#{comment_type(comment)}-reply-tray")
    end
  end

  def comment_type(comment)
    is_reply?(comment) ? :reply : :comment
  end

  def is_reply?(comment)
    comment.is_a?(Anchor::CommentReply)
  end

  def listing_likers(likes_summary, viewer)
    if likes_summary.liker_ids.any?
      users = viewer ? viewer.find_ordered_by_following_and_followers(likes_summary.liker_ids) :
        User.find_ordered_by_followers(likes_summary.liker_ids)
      if users.any?
        likers = []
        pics = []
        you_only = false

        # viewer is the first liker, shown as 'You'
        if viewer
          me = users.delete(viewer)
          if me
            you_only = true
            likers << link_to_user_profile(me, text: 'You')
            pics << me
          end
        end

        # the next two likers are shown with their full names
        if users.any?
          you_only = false
          1.upto(2).each do
            if users.any?
              user = users.shift
              likers << link_to_user_profile(user)
              pics << user
            end
          end
        end

        # the rest of the likers are grouped into 'n others'
        if users.any?
          likers << pluralize(users.size, 'other')
          pics.concat(users)
        end

        content_tag :ul do
          content_tag(:li, class: 'love-box-facepile') do
            #XXX: 30 fit on a page now - generalize at some point?
            pics[0..29].inject(''.html_safe) {|m, user| m << user_avatar_xsmall(user, class: 'text-adjacent')}
          end +
          content_tag(:li, class: 'love-box-list') do
            # use the plural form when there is only one subject and it is 'You' as opposed to ('Some User')
            likes_count = likes_summary.count == 1 && you_only ? 2 : likes_summary.count
            t('listings.like_box.like_this_product', likers: likers.to_sentence, count: likes_count).html_safe
          end
        end
      end
    end
  end

  def checkout_price_detail(name, value, id, options = {})
    content_tag :div, {:class => 'price-detail'}.merge(options) do
      out = []
      out << (content_tag(:span, name, :class => 'price-detail-name'))
      formatted_value = raw('$' + content_tag(:span, number_to_unitless_currency(value.abs), id: id))
      formatted_value = "(#{formatted_value})".html_safe if value < 0
      out << (content_tag(:span, formatted_value, :class => 'price-detail-value'))
      out.join('').html_safe
    end
  end

  def email_marketplace_fee_detail(listing)
    listing.buyer_fee > 0 ? number_to_currency(listing.buyer_fee) : t('listings.price_box.fees_waived_email')
  end

  # sanitize HTML content to allow only the tags that are inserted by our wysiwig editor
  WYSIWIG_TAGS = %w(b br div em hr i li ol p span u ul)
  def sanitize_wysiwig(content)
    sanitize(content, tags: WYSIWIG_TAGS, attributes: [])
  end

  def listing_order_box(listing, viewer)
    content_tag(:div, id: "order-info", class: "order-#{listing.order.status} container")
    out = []
    out << listing_trackers(listing)
    out << content_tag(:div, class: "progress-bar-container order") do
      listing_order_progress_bar(listing)
    end
    out << content_tag(:div, id: "order-summary", class: "order-#{listing.order.status} container") do
      exhibit = Listings::OrderExhibit.factory(listing, viewer, self)
      exhibit.render if exhibit
    end
    out << content_tag(:div, id: "order-details", class: "order-#{listing.order.status}") do
      out2 = []
      if feature_enabled?(:feedback)
        out2 << listing_buyer_privacy(listing) if buyer?
      end
      out2 << render('listings/order_details', listing: listing)
      safe_join(out2)
    end
    safe_join(out)
  end

  def listing_seller_box(listing)
    out = []
    if listing.active?
      out << content_tag(:p, t('.seller.status.active'))
      out << content_tag(:div) do
        out2 = []
        out2 << listing_seller_create_button(listing)
        out2 << listing_seller_edit_button(listing)
        out2 << listing_seller_cancel_button(listing)
        safe_join(out2)
      end
      # XXX: move to partials
      if display_requested?(:activation_cta)
        out << render('listings/seller/active_cta_overlay', first: listing.seller.published_listing_count == 1,
                      listing: listing)
      end
      unless listing.seller.default_deposit_account?
        out << render('listings/seller/seller_info_cta_modal', seller: listing.seller)
      end
    elsif listing.incomplete?
      out << content_tag(:p, t('.seller.status.incomplete'))
      out << content_tag(:div) do
        out2 = []
        out2 << listing_seller_complete_button(listing)
        out2 << listing_seller_cancel_button(listing)
        safe_join(out2)
      end
    elsif listing.inactive?
      if guest?
        out << content_tag(:p, t('.seller.status.inactive_guest'))
        out << link_to_facebook_connect(label: t('.seller.status.button.facebook_html'), seller_signup: true,
                                        cl: 'primary button positive large signup facebook')
        out << link_to_twitter_connect(label: t('.seller.status.button.twitter_html'), seller_signup: true,
                                       cl: 'button soft')
      else
        out << content_tag(:div, data: { role: 'inactive-listing-cta' }, class: 'top-cta') do
          out2 = []
          out2 << content_tag(:h1, t('.seller.status.inactive'))
          out2 << content_tag(:p, t('.seller.status.inactive_message_html'))
          out2 << listing_seller_activate_button(listing)
          out2 << listing_seller_edit_button(listing)
          safe_join(out2)
        end
      end
    elsif listing.suspended?
      out << content_tag(:p, t('.seller.status.suspended_html', help_link: link_to_email_us))
      out << content_tag(:div) do
        out2 = []
        out2 << listing_seller_edit_button(listing)
        out2 << listing_seller_go_to_listings_button(listing)
        out2 << listing_seller_cancel_button(listing)
        safe_join(out2)
      end
    elsif listing.cancelled?
      out << content_tag(:p, t('.seller.status.canceled'))
      out << content_tag(:p) do
        out2 = []
        out2 << listing_seller_create_button(listing)
        out2 << listing_seller_go_to_listings_button(listing)
        out2 << tag(:br)
        safe_join(out2)
      end
    end
    safe_join(out)
  end

  def listing_seller_edit_button(listing)
    bootstrap_button(t('.seller.button.edit'), edit_listing_path(listing), data: {action: 'edit'},
                    class: 'margin-right large')
  end

  def listing_seller_cancel_button(listing)
    link_to(t('.seller.button.cancel'), listing_path(listing), method: :delete, data: {action: 'cancel'},
                    confirm: t('.seller.confirm.cancel'), disable_with: t('.seller.disable.cancel_html'),
                    class: 'tertiary-action margin-right')
  end

  def listing_seller_create_button(listing)
    bootstrap_button(t('.seller.button.create'), new_listing_path, data: {action: 'create'},
                    class: 'margin-right primary large')
  end

  def listing_seller_complete_button(listing)
    bootstrap_button(t('.seller.button.complete'), setup_listing_path(listing), data: {action: 'complete'},
                    class: 'margin-right large')
  end

  def listing_seller_activate_button(listing)
    bootstrap_button(t('.seller.button.activate'), activate_listing_path(listing), method: :post,
                     data: {action: 'activate'}, disable_with: t('.seller.disable.activate_html'),
                     class: 'margin-right primary large')
  end

  def listing_seller_go_to_listings_button(listing)
    bootstrap_button(t('.seller.button.listings'), for_sale_dashboard_path, data: {action: 'listings'})
  end

  def listing_more_from_seller(listing)
    count = listing.more_from_this_seller_count
    more_items = count
    if count > 4
      num_to_show = 3
      more_items -= 3
    else
      num_to_show = more_items
      more_items = nil
    end
    listings_to_show = listing.more_from_this_seller.sample(num_to_show)
    photos = ListingPhoto.find_primaries(listings_to_show)
    content_tag(:ul, class: 'thumbnails') do
      out = []
      listings_to_show.inject(out) do |m, listing|
        if photos.key?(listing.id)
          m << content_tag(:li) do
            link_to(listing_photo_tag(photos[listing.id], :medium, title: listing.title), listing_path(listing),
                    class: 'thumbnail')
          end
        end
      end
      if more_items
        out << content_tag(:li, class: 'more-link') do
          link_to(public_profile_path(listing.seller)) do
            content_tag(:span, more_items, class: 'listed-by-stats') +
            content_tag(:span, t('.more_from_seller.more_listings'), class: 'listed-by-stats-header')
          end
        end
      end
      safe_join(out)
    end
  end

  def listing_social_story(story, likes_count, saves_count, options = {})
    out = []
    out << content_tag(:div, class: "social-story-container") do
      if story
        action, actor = story.latest_imperative_action_actor
        content_tag(:span, class: "social-story", data: {role: "social-story"}) do
          out2 = []
          out2 << content_tag(:span, '', class: "icons-ss-#{action}", alt: action)
          if actor
            out2 << actor.name
          else
            out2 << t('listings.stories.no_actor')
          end
          story = safe_join(out2)

          out3 = []
          if actor
            out3 << link_to(story, public_profile_path(actor))
          else
            out3 << story
          end
          out3 << listing_stats(likes_count, saves_count, options)
          bar_separated(*out3)
        end
      end
    end
    safe_join(out)
  end

  def listing_photos(listing, photos)
    out = []

    # main photos - first visible, rest hidden
    out << content_tag(:div, id: 'listing-photos') do
      photos.each.with_index.inject(''.html_safe) do |m, (photo, index)|
        style = index == 0 ? nil : 'display:none'
        # use width to force the browser to scale the 560px wide photo down to 480px. if this causes quality or
        # performance to suffer, we'll need to process a 480px wide version of the photo on the server side.
        tag = listing_photo_tag(photo, :large, id: "photo-#{photo.id}", data: {photo: photo.id}, style: style,
                                width: 460)
        if listing.respond_to?(:source) && listing.source
          m << link_to(tag, external_listing_path(listing), target: '_blank')
        else
          m << tag
        end
      end
    end
    out << listing_thumbnail_photos(listing, photos)
    safe_join(out)
  end

  def listing_thumbnail_photos(listing, photos, options = {}, &block)
    # thumbnail carousel
    # http://stackoverflow.com/questions/9745746/twitter-bootstrap-2-carousel-display-a-set-of-thumbnails-at-a-time-like-jcarou
    content_tag(:div, id: 'listing-thumbnails', class: 'carousel slide', data: {interval: false}) do
      count = options.fetch(:count, 6)
      out = []
      out << content_tag(:div, class: 'carousel-inner') do
        out2 = []
        photos.each_slice(count).with_index do |slice, index|
          classes = ['item']
          classes << 'active' if index == 0
          out2 << content_tag(:div, class: classes.join(' ')) do
            content_tag(:ul, class: 'thumbnails') do
              out3 = []
              slice.each_with_index do |photo, i|
                out3 << if block_given?
                  yield(photo, i)
                else
                  content_tag(:li) do
                    data = {
                      photo: photo.id,
                      role: 'thumbnail'
                    }
                    listing_photo_tag(photo, :xsmall, id: "thumbnail-#{photo.id}", width: 50, height: 50, data: data)
                  end
                end
              end
              if options[:total_count]
                ((count+1).upto(options[:total_count])).each do
                  out3 << content_tag(:div, '', class: 'placeholder')
                end
              end
              safe_join(out3)
            end
          end
        end
        safe_join(out2)
      end
      if options.fetch(:navigation, true)
        out << link_to('‹', '#listing-thumbnails', class: 'carousel-control left', data: {slide: 'prev'})
        out << link_to('›', '#listing-thumbnails', class: 'carousel-control right', data: {slide: 'next'})
      end
      safe_join(out)
    end
  end

  def save_listing_to_collection_id(suffix = nil, options = {})
    id = [options[:source] == 'listing_modal' ? 'listing-modal' : 'listing']
    id << 'save-to-collection'
    id << suffix if suffix
    id.join('-')
  end

  def save_listing_to_collection_button_and_modal(listing, collections, saved, options = {})
    out = []
    out << save_listing_to_collection_button(listing, saved, options)
    out << save_listing_to_collection_modal(listing, collections, options)
    safe_join(out)
  end

  def save_listing_to_collection_button(listing, saved, options = {})
    id = options[:id] || save_listing_to_collection_id(listing.id, options)
    button_options = options.fetch(:button_options, {}).reverse_merge(
      type: :button,
      action_type: :curatorial,
      actioned: saved,
      toggle_modal: id,
      data: {
        action: 'save-to-collection-cta',
        disable_with: t('listings.save_to_collection.button.save.disable_html')
      }
    )
    out = []
    out << bootstrap_button(button_options) do
      out2 = []
      out2 << content_tag(:span, nil, class: 'icons-button-save')
      out2 << t("listings.save_to_collection.button.#{saved ? 'saved' : 'save'}.text")
      safe_join(out2)
    end
    safe_join(out)
  end

  def save_listing_to_collection_modal(listing, collections, options = {})
    id = options[:id] || save_listing_to_collection_id(listing.id, options)
    classes = 'save-to-collection save-to-collection-v2'
    out = []
    out << bootstrap_modal(id, t('listings.save_to_collection.modal.title'),
                           data: {role: 'save-manager', include_source: true,
                                  url: save_modal_listing_collections_path(listing)},
                           remote: true, show_close: false, class: classes) do
    end
    safe_join(out)
  end

  def save_listing_to_collection_modal_contents(listing, collections, price_alert, options = {})
    out = []
    id = options[:id] || save_listing_to_collection_id(listing.id, options)
    out << content_tag(:div, class: 'product-image-container') do
      listing_photo_tag(options[:photo] || listing.photos.first, :px_220x220, title: listing.title,
                        class: 'product-image')
    end
    out << save_listing_to_collection_form(id, listing, collections, price_alert)
    safe_join(out)
  end

  def save_listing_to_collection_have_checkbox(listing, collections)
    out = []
    if feature_enabled?('collections.have')
      div_options = {
        class: 'modal-checkbox-cta',
        data: {role: 'have'}
      }
      div_options[:style] = 'display:none' unless collections.any? && collections.first.have?
      out << content_tag(:div, div_options) do
        bootstrap_check_box_tag(:have, t('listings.save_to_collection.modal.have.label'), "1", false,
                                id: "have_#{listing.id}")
      end
    end
    safe_join(out)
  end

  def save_listing_to_collection_want_checkbox(listing, collections)
    out = []
    if feature_enabled?('collections.want')
      # user should not see this check box. we check it dynamically when the user chooses a want collection.
      out << content_tag(:div, data: {role: 'want'}, style: 'display:none') do
        bootstrap_check_box_tag(:want, nil, '1', false, id: "want_#{listing.id}")
      end
    end
    safe_join(out)
  end

  def save_listing_to_collection_form(id, listing, collections, price_alert)
    # Our initially displayed collection is the one that was created most recently.
    bootstrap_form_tag(listing_collections_path(listing), method: :put, remote: true,
      class: 'listing-save-to-collection', id: "#{id}-form", data: {role: 'save-to-collection-form-v2'}) do
      out = []
      out << save_listing_to_collection_form_contents_collections(listing, collections)
      out << save_listing_to_collection_form_contents_price_alert(listing, price_alert)
      out << save_listing_to_collection_have_checkbox(listing, collections)
      out << save_listing_to_collection_want_checkbox(listing, collections)
      safe_join(out)
    end
  end

  def save_listing_to_collection_form_contents_collections(listing, collections)
    out = []
    out << label_tag(:collection_slugs, t('listings.save_to_collection.modal.collection_label'),
                     for: "collection_ids_#{listing.id}", class: 'big-label')
    out << save_listing_to_collection_multi_selector(listing, collections)
    safe_join(out)
  end

  def save_listing_to_collection_form_contents_price_alert(listing, price_alert)
    out = []
    if feature_enabled?('listings.price_alert')
      out << content_tag(:div, class: 'price-alert-container') do
        out2 = []
        out2 << content_tag(:label, class: 'big-label') do
          t('listings.save_to_collection.modal.price_alert.instructions')
        end
        out2 << text_field_tag(:price_alert, price_alert.threshold, id: "price-alert-#{listing.id}")
        out2 << content_tag(:div, class: 'slider-labels') do
          out3 = []
          out3 << content_tag(:span, t('listings.save_to_collection.modal.price_alert.0'))
          out3 << content_tag(:span, t('listings.save_to_collection.modal.price_alert.25'), class: 'off-25')
          out3 << content_tag(:span, t('listings.save_to_collection.modal.price_alert.50'), class: 'off-50')
          out3 << content_tag(:span, t('listings.save_to_collection.modal.price_alert.75'), class: 'off-75')
          out3 << content_tag(:span, t('listings.save_to_collection.modal.price_alert.100'), class: 'off-none')
          safe_join(out3)
        end
        safe_join(out2)
      end
    end
    safe_join(out)
  end

  def save_listing_to_collection_form_contents_comment(options = {})
    comment_options = {
      placeholder: t('listings.save_to_collection.modal.comment.placeholder_html'),
      class: 'listing-save-to-collection-comment',
      data: {role: 'comment'}, autofocus: :autofocus
    }.reverse_merge(options)
    out = []
    out << label_tag(:comment_label, t('listings.save_to_collection.modal.comment_label'), class: 'big-label')
    out << text_area_tag(:comment, nil, comment_options)
    safe_join(out)
  end

  def save_external_listing_to_collection_contents(listing, collections, price_alert, options = {})
    out = []
    out << content_tag(:div, data: {role: 'save-manager'}) do
      out2 = []
      out2 << content_tag(:div, class: 'product-image-container') do
                          listing_photo_tag(options[:photo] || listing.photos.first, :px_220x220, title: listing.title,
                                            class: 'product-image')
      end
      out2 << content_tag(:div, class: 'hidden-modal') do
        out3 = []
        out3 << content_tag(:h1, class: 'page-title') do
          text = []
          text << content_tag(:div, class: 'alert-success-message') do
            t('.successfully_added')
          end
          text << t('.save_to_collections')
          safe_join(text)
        end
        safe_join(out3)
      end
      out2 << save_external_listing_to_collection_form(listing, collections, price_alert)
      safe_join(out2)
    end
    safe_join(out)
  end

  def save_external_listing_to_collection_form(listing, collections, price_alert)
    bootstrap_form_tag(listing_collections_path(listing), method: :put,
      class: 'listing-save-to-collection', id: "#{listing.id}-form", data: {role: 'save-to-collection-form-v2'}) do
      out = []
      out << save_listing_to_collection_form_contents_collections(listing, collections)
      out << content_tag(:div, class: "control-group") do
        out2 = []
        text_options = listing_comment_box_options(listing)
        out2 << save_listing_to_collection_form_contents_comment(text_options)
        safe_join(out2)
      end
      out << save_listing_to_collection_form_contents_price_alert(listing, price_alert)
      out << hidden_field_tag('redirect', complete_listing_bookmarklet_path(listing))
      out << bootstrap_submit_tag(t('.button.submit'), class: 'xlarge')
      out << save_listing_to_collection_skip_button(listing)
      safe_join(out)
    end
  end

  def save_listing_to_collection_skip_button(listing)
    bootstrap_button(t('.button.skip'), complete_listing_bookmarklet_path(listing),
      class: 'large pull-right', data: {action: 'save-skip'})
  end

  def save_listing_to_collection_dropdown(collections, options = {})
    title_collection = collections.any?? collections.max_by(&:created_at) : Collection.new
    out = []
    out << bootstrap_dropdown(class: 'copious-input-select',
                              data: {role: 'collections-list'}) do
      out2 = []
      out2 << bootstrap_dropdown_toggle(title_collection.name, caret: true)
      out2 << bootstrap_dropdown_menu(save_listing_to_collection_list(collections, options))
      safe_join(out2)
    end
    out << hidden_field_tag('collection_ids[]', title_collection.slug, data: {role: 'collection-id'})
    safe_join(out)
  end

  def save_listing_to_collection_multi_selector(listing, collections, options = {})
    already_saved_collections = listing.collections_owned_by(current_user)
    content_tag(:div, data: {role: 'multi-collection-selector'}, class: 'well well-small well-border') do
      out = []
      out << content_tag(:div, class: 'well-header well-header-small scrollable', data: {role: 'multi-selector'}) do
        content_tag(:div, data: {role: 'selectables'}, class: 'multi-selector') do
          out2 = []
          collections.sort_by {|c| c.name.downcase }.each do |collection|
            selected = already_saved_collections.include?(collection)
            out2 << save_listing_to_collection_selectable(collection, options.reverse_merge(selected: selected))
          end
          safe_join(out2)
        end
      end
      out << content_tag(:div, class: 'well-footer well-footer-small') do
        new_collection_input_and_button
      end
      safe_join(out)
    end
  end

  def save_listing_to_collection_selectable(collection, options = {})
    data = {role: 'selectable', collection: collection.slug}
    data[:collection_type] = collection.type unless collection.generic?
    content_tag(:label, data: data, class: 'checkbox') do
      check_box_tag('collection_slugs[]', collection.slug, options[:selected], class: 'checkbox') + collection.name.html_safe
    end
  end

  def save_listing_to_collection_list(collections, options = {})
    list = []
    if options[:include_none]
      list << [t('listings.save_to_collection.modal.collection.none.label_html'), nilhref,
               data: {:'collection-id' => nil}]
    end
    list += collections.sort_by {|c| c.name.downcase}.map do |collection|
      data = {:'collection-id' => collection.slug}
      data[:collection_type] = collection.type unless collection.generic?
      [collection.name, public_profile_collection_path(current_user.id, collection.slug), data: data]
    end
    list << ['', nil, class: 'divider', data: {role: 'divider'}]
    list << new_collection_input_and_button
    list
  end

  def want_listing_modal(listing, collection, want)
    bootstrap_modal("listing-want-#{listing.id}",
                    t('listings.save_to_collection.want_modal.title', collection: collection.name),
                    remote: true, show_success: true, show_close: false, data: {role: 'want-modal'},
                    custom_links: want_listing_skip_button(listing, collection), class: 'want-modal') do
      want_listing_modal_content(listing, collection, want)
    end
  end

  def want_listing_skip_button(listing, collection)
    bootstrap_button(t('listings.save_to_collection.want_modal.skip'), complete_listing_collection_wants_path(listing, collection),
                     class: 'large pull-right', data: {remote: true, action: 'want-skip'})
  end

  def want_listing_modal_content(listing, collection, want)
    out = []
    out << content_tag(:p) do
      t('listings.save_to_collection.want_modal.instructions_html')
    end
    url = want.new_record? ? listing_collection_wants_path(listing, collection) : listing_collection_want_path(listing, collection, want)
    out << bootstrap_form_for(want, url: url, html: {
                                id: "listing-want-#{listing.id}-form", data: {condition: :primary, remote: true}
                              }) do |f|
      out2 = []
      out2 << f.number_field(:max_price, t('listings.save_to_collection.want_modal.max_price.label'),
                             id: "want_max_price_#{listing.id}", maxlength: 18, step: 'any', prepend: raw('&#36;'),
                             value: number_to_unitless_currency(f.object.max_price), class: 'want_max_price')
      out2 << f.select(:condition, t('listings.save_to_collection.want_modal.condition.label'),
                       want_listing_condition_choices_for_select, {}, id: "want_condition_#{listing.id}",
                       class: 'want_condition')
      out2 << f.text_area(:notes, t('listings.save_to_collection.want_modal.notes.label'),
                          id: "want_notes_#{listing.id}",
                          placeholder: t('listings.save_to_collection.want_modal.notes.placeholder_html'),
                          class: 'want_notes')
      safe_join(out2)
    end
    safe_join(out)
  end

  def want_listing_condition_choices_for_select
    Want::CONDITIONS.map do |condition|
      [t(condition, scope: 'models.want.attributes.condition'), condition]
    end
  end

  def save_listing_to_collection_success_modal(listing, have = nil)
    modal_options = {
      class: 'success-modal',
      show_success: true,
      data: {
        role: 'save-manager-success-modal',
        auto_hide: true
      }
    }
    if have
      modal_options[:save_button_text] = t('listings.save_to_collection.success_modal.button.save.label')
      modal_options[:show_close] = false
      modal_options[:remote] = true
    else
      modal_options[:show_save] = false
      modal_options[:show_footer] = false
    end
    more = listing.more_from_this_seller(limit: Collection.config.success_modal.listing_count)
    photos = ListingPhoto.find_primaries(more)
    bootstrap_modal("listing-save-to-collection-success-#{listing.id}",
                    t('listings.save_to_collection.success_modal.title'), modal_options) do
      out = []
      if more.any?
        out << content_tag(:p) do
          t('listings.save_to_collection.success_modal.more_from_seller', seller: listing.seller.name)
        end
        out << content_tag(:ul, class: 'pull-left thumbnails') do
          out2 = []
          more.each do |l|
            photo = photos[l.id]
            if photo
              out2 << content_tag(:li) do
                link_to(listing_photo_tag(photo, :medium), listing_path(l), class: 'thumbnail',
                        data: {toggle: 'listing-modal', listing: l.id, url: listing_modal_path(l)})
              end
            end
          end
          safe_join(out2)
        end
      end
      if have
        out << bootstrap_form_tag(new_listing_path, method: :get, data: {condition: :primary},
                                  id: "listing-save-to-collection-success-#{listing.id}-form")
      end
      safe_join(out)
    end
  end

  def listing_love_button_container(listing, like, options = {})
    data = {listing: listing.id}
    data[:source] = options[:source] if options[:source]
    content_tag(:div, class: 'pull-left', data: data) do
      listing_love_button(listing, !!like)
    end
  end

  def listing_love_button(listing, loved, options = {})
    # used to render listing love buttons all over the site (eg on product cards). be aware that if you make changes
    # they will be applied to all listing love buttons, not just the one on the listing page.
    out = []
    if logged_in? && listing.loveable?
      unlike_url = options.delete(:unlike_url) || unlike_listing_path(listing)
      like_url = options.delete(:like_url) || like_listing_path(listing)
      link_options = {
        action_type: :curatorial,
        type: :button,
        data: {
          toggle: 'love'
        }
      }.merge(options)
      if loved
        link_options[:data][:target] = unlike_url
        link_options[:data][:method] = :delete
        link_options[:data][:action] = 'unlove'
        link_options[:actioned] = true
      else
        link_options[:data][:target] = like_url
        link_options[:data][:method] = :put
        link_options[:data][:action] = 'love'
      end
      out << bootstrap_button(link_options) do
        listing_love_button_content(loved)
      end
    else
      out << listing_love_button_content(loved)
    end
    safe_join(out)
  end

  def listing_love_button_content(loved)
    # used to render listing love buttons all over the site (eg on product cards). be aware that if you make changes
    # they will be applied to all listing love buttons, not just the one on the listing page.
    classes = %w(icons-button-love)
    classes << 'inactive' if loved
    out = []
    out << content_tag(:span, nil, class: class_attribute(classes), data: {role: 'love-button-content'})
    out << (loved ? t('listings.show.love_button.loved') : t('listings.show.love_button.love'))
    safe_join(out)
  end

  def listing_comment_box(listing, viewer)
    content_tag(:div, id: 'listing-feed-comment-entry', data: {source: 'listing-page', :'include-source' => true}) do
      out = []
      if logged_in?
        out << user_avatar_small(viewer, id: 'comment-avatar')
        out << form_for(Anchor::Comment.new, as: :comment, url: listing_comments_path(listing), remote: true) do |f|
          f.field(:text, container: :div) do
            text_options = listing_comment_box_options(listing)
            f.text_area(:text, text_options)
          end
        end
        out << content_tag(:span, t('.comment_box.help'), id: 'comment-help', style: 'display: none')
      else
        out << content_tag(:div, t('.comment_box.placeholder_html'), id: 'faux-field-text')
      end
      safe_join(out)
    end
  end

  def listing_comment_box_options(listing)
    typeahead = feature_enabled?('listings.comments.typeahead')
    placeholder_key = typeahead ? 'placeholder_typeahead_html' : 'placeholder_html'
    text_options = {
      placeholder: t(".comment_box.#{ placeholder_key }"),
      disabled: !listing.commentable?,
      maxlength: Listings::Comments::COMMENT_MAX_LENGTH
    }
    text_options[:data] = { control: 'commentbox' } if typeahead
    text_options
  end

  def listing_comment_feed(feed, viewer)
    out = []
    out << content_tag(:ul, id: 'feed', class: 'comments comment-striped', data: {source: 'listing-page'}) do
      if feed.comments.any?
        out2 = []
        feed.comments.each do |comment|
          out2 << content_tag(:li, listing_comment(feed, comment, viewer), id: "listing-feed-comment-#{comment.id}",
                              class: 'listing-feed-comment', data: {listing: feed.listing.id, comment: comment.id})
        end
        safe_join(out2)
      end
    end
    out << listing_comment_feed_templates(feed)
    safe_join(out)
  end

  def listing_comment(feed, comment, viewer)
    ctype = comment_type(comment)
    commenter = feed.users[comment.user_id]
    replies = feed.replies.fetch(comment, [])

    out = []
    out << content_tag(:a, nil, name: "comment-#{comment.id}")

    if admin?
      out << listing_comment_flags(feed, comment)
    end

    out << user_avatar_small(commenter, class: 'text-adjacent')

    out << content_tag(:div, class: "listing-feed-#{ctype}-container") do
      out2 = []

      out2 << link_to_user_profile(commenter, class: 'commenter-name')
      out2 << content_tag(:div, comment_clean(comment, commenter), class: "listing-feed-#{ctype}-text")

      out2 << content_tag(:div, class: "listing-feed-#{ctype}-action") do
        out3 = []
        if logged_in?
          if feed.listing.commentable?
            out3 << link_to_reply_to_comment(comment)
          end
          out3 << link_to_flag_comment(comment, viewer)
        end
        out3 << t('.comment.timestamp', timestamp: time_ago_in_words(comment.created_at))
        if admin?
          out3 << content_tag(:div, class: "admin-container") do
            out4 = []
            out4 << link_to_delete_comment(feed.listing, comment)
            out4 << link_to_unflag_comment(feed.listing, comment)
            case ctype
            when :comment
              if feed.listing.seller != commenter
                out4 << link_to_resend_comment_email(feed.listing, comment)
              end
            when :reply
              original_comment = feed.comments_by_id[comment.parent_id]
              if original_comment
                original_commenter = original_comment && feed.users[original_comment.user_id]
                if original_commenter != commenter
                  out4 << link_to_resend_comment_email(feed.listing, comment)
                end
              end
            end
            safe_join(out4)
          end
        end
        safe_join(out3)
      end

      if logged_in?
        out2 << listing_comment_flag_tray(comment, viewer)
      end

      replies.each do |reply|
        out2 << content_tag(:div, id: "listing-feed-reply-#{reply.id}", class: 'listing-feed-reply',
                            data: {listing: feed.listing.id, comment: comment.id, reply: reply.id}) do
          listing_comment(feed, reply, viewer)
        end
      end

      if logged_in?
        out2 << listing_comment_reply_tray(comment)
      end

      safe_join(out2)
    end

    safe_join(out)
  end

  def listing_comment_flags(feed, comment)
    flaggers = feed.flaggers[comment]
    out = []
    comment.grouped_flags.each_pair do |reason, flags_for_reason|
      out << content_tag(:h3, class: 'flag-reason') do
        by = if flaggers && flaggers.include?(reason) && flaggers[reason].any?
          t('.comment.flags.flagged_by_html', flagger_link: link_to_user_profile(flaggers[reason].first),
            count: flaggers[reason].size)
        end
        r = t('.comment.flags.flagged_for_html', reason: reason)
        t('.comment.flags.flagged_html', count: flags_for_reason.size, by: by, reason: r)
      end
      flags_for_reason.find_all { |f| f.description.present? }.each do |flag|
        out << content_tag(:blockquote, full_clean(flag.description))
      end
    end
    safe_join(out)
  end

  def listing_comment_feed_templates(feed)
    # XXX: move templates to handlebars files in templates dir
    out = []

    out << handlebar_template('listing-comment-flag-template') do
      out2 = []
      out2 << content_tag(:h3, 'Report this comment as inappropriate')
      out2 << content_tag(:p, 'Please select a category that most closely reflects your concerns so that we can review it & more promptly address your concerns.')
      out2 << form_tag(listing_comment_flags_path(feed.listing, ':commentId'), remote: true) do
        out3 = []
        out3 << listing_comment_flag_reason_select_tag(:reason, params[:reason])
        out3 << text_area_tag(:description, params[:description], placeholder: 'Please describe briefly why you have flagged this comment.')
        out3 << content_tag(:p, 'We take flagging very seriously. Abuse of flagging will result in account suspension.', class: 'small')
        out3 << content_tag(:div, class: 'buttons-container marginBottom') do
          buttons(save_text: 'Flag this comment', class: 'button marginRight', cancel_url: nilhref,
                  cancel_options: {class: 'listing-comment-flag-cancel'})
        end
        safe_join(out3)
      end
      safe_join(out2)
    end

    out << handlebar_template('listing-reply-flag-template') do
      out2 = []
      out2 << content_tag(:h3, 'Report this comment as inappropriate')
      out2 << content_tag(:p, 'Please select a category that most closely reflects your concerns so that we can review it & more promptly address your concerns.')
      out2 << form_tag(listing_comment_reply_flags_path(feed.listing, ':commentId', ':replyId'), remote: true) do
        out3 = []
        out3 << listing_comment_flag_reason_select_tag(:reason, params[:reason])
        out3 << text_area_tag(:description, params[:description], placeholder: 'Please describe briefly why you have flagged this comment.')
        out3 << content_tag(:div, class: 'buttons-container marginBottom') do
          buttons(save_text: 'Flag this comment', class: 'button marginRight', cancel_url: nilhref,
                  cancel_options: {class: 'listing-reply-flag-cancel'})
        end
        safe_join(out3)
      end
      out2 << content_tag(:p, 'We take flagging very seriously. Abuse of flagging will result in account suspension.', class: 'small')
      safe_join(out2)
    end

    out << handlebar_template('listing-comment-reply-template') do
      out2 = []
      out2 << content_tag(:h3, 'Post a reply')
      out2 << form_tag(listing_comment_replies_path(feed.listing, ':commentId'), remote: true, data: {:'include-source' => true}) do
        field(:text, container: :div) do
          out3 = []
          out3 << text_area_tag(:text, params[:text], maxlength: Listings::Comments::COMMENT_MAX_LENGTH, placeholder: 'Write a reply...',
                                id: "comment-reply-{{commentId}}", data: {role: 'comment-reply',
                                control: if feature_enabled?('listings.comments.typeahead') then 'commentbox' else '' end})
          out3 << content_tag(:span, 'Press Enter to post.', data: {role: 'comment-reply-help'},
                              class: 'comment-reply-help', style: 'display: none')
          out3 << content_tag(:div, class: 'buttons-container pull-right') do
            link_to('Cancel', nilhref, class: 'listing-comment-reply-cancel')
          end
          safe_join(out3)
        end
      end
      safe_join(out2)
    end

    safe_join(out)
  end

  def listing_love_box(likes_summary, viewer)
    content_tag(:div, id: 'love-box-facepile') do
      if likes_summary.count > 0
        listing_likers(likes_summary, viewer)
      else
        content_tag(:div, '', id: 'first-to-love') + t('.love_box.cta')
      end
    end
  end

  def listing_price_box(listing, viewer)
    out = []

    # original price
    if listing.supports_original_price? && listing.original_price?
      out << content_tag(:h1, data: {role: 'original-price', amount: number_to_currency(listing.original_price)},
                         id: 'original-price') do
        number_to_currency(listing.original_price)
      end
    end

    # price
    # buyer wants to see final adjusted price, not list price
    price = buyer? ? listing.order.total_price : listing.price
    price_options = { id: 'listing-price', data: { role: 'price', amount: number_to_currency(price) } }
    price_options[:class] = 'original-price-present' if listing.original_price?
    out << content_tag(:h1, price_options) do
      number_to_currency(price)
    end
    if listing.respond_to?(:source)
      out << content_tag(:p, " on #{listing.source.domain}", class: 'external-listing-url')
    end

    # shipping
    if listing.supports_shipping?
      out << content_tag(:div, data: {role: 'shipping', amount: number_to_currency(listing.shipping)},
                         id: 'shipping-container') do
        if listing.free_shipping?
          content_tag(:span, t('.price_box.free_shipping'))
        else
          content_tag(:span, t('.price_box.shipping', shipping: number_to_currency(listing.shipping)))
        end
      end
    end

    # status
    if listing.sold?
      bought_on = date(listing.order.confirmed_at || listing.order.created_at)
      if buyer?
        out << content_tag(:p, t('.price_box.sold.buyer_html', bought_on: bought_on))
      elsif seller?
        buyer_link = link_to_user_profile(listing.buyer)
        out << content_tag(:p, t('.price_box.sold.seller_html', bought_on: bought_on, buyer_link: buyer_link))
      else
        out << content_tag(:p, t('.price_box.sold.other_html', bought_on: bought_on))
      end
    elsif listing.active?
      if buyer?
        if listing.supports_checkout?
          if listing.order.shipping_address
            out << content_tag(:div) do
              listing_price_box_payment_button(listing)
            end
          else
            out << content_tag(:div) do
              listing_price_box_shipping_button(listing)
            end
          end
        end
      elsif seller?
        out << content_tag(:div) do
          out2 = []
          out2 << listing_price_box_buy_now_button(listing, disabled: true)
          if feature_enabled?(:make_an_offer) && listing.supports_make_an_offer?
            out2 << listing_price_box_make_an_offer(listing, viewer, disabled: true)
          end
          safe_join(out2)
        end
      else
        if listing.order
          # order in checkout
          out << content_tag(:p, t('.price_box.active.in_checkout'))
        else
          # up for grabs!
          out << content_tag(:div) do
            out2 = []
            out2 << listing_price_box_buy_now_button(listing)
            if feature_enabled?('listings.recommend') && logged_in? && listing.supports_recommend?
              out2 << content_tag(:p, 'or', style: 'text-align: center; line-height: 30px; margin-bottom: 0;')
              out2 << recommend_button
            end
            if feature_enabled?(:make_an_offer) && listing.supports_make_an_offer?
              out2 << listing_price_box_make_an_offer(listing, viewer)
            end
            if feature_enabled?('listings.recommend') && logged_in? && listing.supports_recommend?
              out2 << recommend_modal(current_user, listing)
            end
            safe_join(out2)
          end
        end
      end
    elsif listing.suspended?
      out << content_tag(:p, t('.price_box.suspended'))
    elsif listing.cancelled?
      out << content_tag(:p, t('.price_box.canceled'))
    end

    safe_join(out)
  end

  def listing_price_box_payment_button(listing)
    bootstrap_button(t('.price_box.button.payment'), payment_listing_purchase_url(listing, secure: true),
                     data: {action: 'payment'}, class: 'full-width', id: 'enter-payment-info')
  end

  def listing_price_box_shipping_button(listing)
    bootstrap_button(t('.price_box.button.shipping'), shipping_listing_purchase_path(listing),
                     data: {action: 'shipping'}, class: 'full-width', id: 'enter-shipping-info')
  end

  def listing_price_box_buy_now_button(listing, options = {})
    html_options = {data: {action: 'buy'}, id: 'buy-button'}
    if options[:disabled]
      url = nilhref
      html_options[:class] = 'disabled'
    elsif listing.respond_to?(:source) && listing.source
      url = external_listing_path(listing)
      html_options[:target] = '_blank'
      html_options[:data][:role] = 'external-listing-link'
    else
      url = listing_purchase_path(listing)
    end
    bootstrap_button(t('.price_box.button.buy_now'), url, html_options)
  end

  def listing_price_box_make_an_offer(listing, viewer, options = {})
    disabled = options[:disabled] || options[:offer] || viewer.nil? || listing.has_offer_from?(viewer)
    content_tag(:div, id: 'price-box-make-an-offer') do
      out3 = []
      out3 << listing_price_box_make_an_offer_button(listing, viewer, disabled: disabled)
      safe_join(out3)
    end
  end

  def listing_price_box_make_an_offer_button(listing, viewer, options = {})
    button_options = {
      id: 'make-an-offer-button',
      name: 'make-an-offer-button',
      type: :button,
      class: 'full-width ',
      data: {
        action: 'make-an-offer'
      }
    }
    if options[:disabled]
      button_options[:class] = 'disabled full-width'
      button_options[:disabled] = true
    else
      button_options[:toggle_modal] = 'make-an-offer'
    end
    out = []
    out << bootstrap_button(t('.price_box.button.make_an_offer'), nil, button_options)
    out << listing_make_an_offer_modal(listing, viewer) unless options[:disabled]
    safe_join(out)
  end

  def listing_make_an_offer_modal(listing, viewer)
     bootstrap_modal('make-an-offer', t('.modal.make_an_offer.title'), remote: true,
                     save_button_text: t('.modal.make_an_offer.button.save'), show_close: false,
                     data: {offerer: viewer.slug, listing: listing.slug, refresh: '#price-box-make-an-offer'}) do
       listing_make_an_offer_modal_content(listing, ListingOffer.new)
    end
  end

  def listing_make_an_offer_modal_content(listing, offer)
    out = []
    out << content_tag(:p) do
      t('.modal.make_an_offer.instructions_html')
    end
    out << bootstrap_form_for(offer, as: :offer, url: listing_offers_path(listing), remote: true,
                              horizontal: true) do |f|
      out2 = []
      out2 << f.control_group(:price) do
        out3 = []
        out3 << f.control_label(:price, t('.modal.make_an_offer.price.label'))
        out3 << f.controls do
          content_tag(:span, id: 'offer_price') do
            price = number_to_currency(listing.price, precision: 2)
            if listing.free_shipping?
              t('.modal.make_an_offer.free_shipping_html', price: price)
            else
              t('.modal.make_an_offer.shipping_html', price: price,
                shipping: number_to_currency(listing.shipping, precision: 2))
            end
          end
        end
        safe_join(out3)
      end
      out2 << f.text_field(:amount, t('.modal.make_an_offer.amount.label'), prepend: '&#36;'.html_safe,
                           placeholder: t('.modal.make_an_offer.amount.placeholder'),
                           value: number_with_precision(f.object.amount, precision: 2))
      duration_choices = (1..7).map { |n| [pluralize(n, 'day'), n.days] }
      out2 << f.select(:duration, t('.modal.make_an_offer.duration.label'), duration_choices, {})
      out2 << f.text_area(:message, t('.modal.make_an_offer.message.label'))
      safe_join(out2)
    end
    safe_join(out)
  end

  def listing_make_an_offer_success_modal(listing, offer, viewer)
     bootstrap_modal('make-an-offer-success', t('.modal.make_an_offer.success.title'), show_save: false) do
       out = []
       out << content_tag(:p) do
         t('.modal.make_an_offer.success.instructions')
       end
       safe_join(out)
    end
  end

  def listing_description(listing)
    if listing.description.present?
      content_tag(:div, id: 'description', class: 'clear', data: {role: 'excerpt'}) do
        out = []
        out << content_tag(:div, id: 'description-truncated', data: {role: 'excerpt-truncated'}) do
          sanitize_wysiwig(listing.description)
        end
        out << link_to(t(".description.more"), "#description-full",
                        data: {toggle: 'excerpt', text: "#description-truncated"})
        out << content_tag(:div, id: 'description-full', data: {role: 'excerpt-full'}, style: 'display:none') do
          sanitize_wysiwig(listing.description)
        end
        out << link_to(t(".description.less"), '#description-truncated', style: 'display:none',
                        data: {toggle: 'excerpt', text: '#description-full'})
        safe_join(out)
      end
    end
  end

  def listing_details(listing)
    content_tag(:ul, :class => 'horizontal-list') do
      out = []

      if listing.category
        out << content_tag(:li, :class => 'title') do
          t('.details.category')
        end
        out << content_tag(:li) do
          link_to(listing.category.name, browse_for_sale_path(listing.category))
        end

        if listing.supports_dimensions?
          listing.category.dimensions.each do |dimension|
            out << content_tag(:li, :class => 'title') do
              t(".details.#{dimension.slug}", name: dimension.name)
            end
            out << content_tag(:li) do
              listing_dimension_value(listing, dimension)
            end
          end
        end
      end

      if listing.size
        out << content_tag(:li, :class => 'title') do
          t('.details.size')
        end
        out << content_tag(:li, data: {role: 'listing-size'}) do
          listing.size.name
        end
      end

      if listing.brand
        out << content_tag(:li, :class => 'title') do
          t('.details.brand')
        end
        out << content_tag(:li) do
          listing.brand.name
        end
      end

      if listing.supports_handling?
        out << content_tag(:li, :class => 'title') do
          t('.details.handling')
        end
        out << content_tag(:li) do
          t('.details.handling_to_ship', duration: count_of_days_in_words(listing.handling_duration))
        end
      end

      if listing.tags.any?
        out << content_tag(:li, :class => 'title') do
          t('.details.tags')
        end
        tag_links = listing.tags.map do |tag|
          link_to(tag.primary.name, browse_for_sale_path(path_tags: tag.primary.slug))
        end
        out << content_tag(:li, :class => 'tags') do
          tag_links.join(', ').html_safe
        end
      end

      safe_join(out)
    end
  end

  def listing_share_box(listing, photo)
    ul_options = {
      class: 'horizontal-list'
    }
    ul_options[:class] << ' logged-out' unless logged_in?
    content_tag(:ul, ul_options) do
      out = []
      # these icons just pop up sharing dialogs
      Network.shareable.each do |network|
        out << content_tag(:li, id: "share-listing-#{network}") do
          if listing.shareable?
            photo_id = photo && photo.id
            link_options = {
              target: '_blank',
              title: t('.share_box.title', network: t(".share_box.network.#{network}")),
              class: 'social-action',
              data: {
                role: 'share',
                network: network,
                social_action: share_action(network)
              },
              rel: :nofollow
            }
            link_to('', share_listing_path(listing, network, photo_id: photo_id), link_options)
          end
        end
      end
      safe_join(out)
    end
  end

  # @option options [Boolean] :full_thanks (+false+) show the full thanks message instead of the minimal one
  def listing_report_box(listing, viewer, options = {})
    out = []
    if viewer.flagged?(listing)
      out << listing_reported_button(listing)
      out << tag(:br)
      out << (options[:full_thanks] ? t('.report_box.thanks.full') : t('.report_box.thanks.minimal'))
    else
      out << listing_report_button(listing)
    end
    safe_join(out)
  end

  def listing_reported_button(listing)
    # XXX: MOH- style as necessary for disabled state
    content_tag(:div, t('.report_box.button.reported'))
  end

  def listing_report_button(listing)
    remote_link(t('.report_box.button.report'), flag_listing_path(listing), class: 'tertiary-action', method: :put,
                refresh: '#report-box', disable_with: t('.report_box.disable.report_html'), data: {action: 'report'})
  end

  def listing_admin_box(listing)
    out = []
    out << content_tag(:p) do
      out2 = []
      out2 << bootstrap_button(t('.admin_box.button.listing'), admin_listing_path(listing.id), class: 'margin-right')
      if listing.order
        out2 << bootstrap_button(t('.admin_box.button.order'), admin_order_path(listing.order.id))
        out2 << tag(:br)
      end
      safe_join(out2)
    end
    safe_join(out)
  end

  def listing_og_meta_tags(listing, photos, likes_summary)
    doc_header do
      out = []
      if feature_enabled?(:networks, :facebook, :open_graph, :object, :listing)
        out << tag(:meta, property: 'og:type', content: 'copious:listing')
        out += listing.tags.map do |t|
          tag(:meta, property: 'copious:tags', content: browse_for_sale_url(path_tags: t.slug))
        end
        out << tag(:meta, property: 'copious:category', content: browse_for_sale_url(listing.category))
      else
        out << tag(:meta, property: 'og:type', content: 'product')
      end
      out << tag(:meta, property: 'og:title', content: listing.title)
      out += photos.map { |photo| tag(:meta, property: 'og:image', content: absolute_url(photo.file.large.url)) }
      out << tag(:meta, property: 'og:url', content: listing_url(listing))
      out << tag(:meta, property: 'og:site_name', content: 'Copious')
      out << tag(:meta, property: 'og:description', content: t('.open_graph.description'))
      out << tag(:meta, property: 'fb:app_id', content: Network::Facebook.app_id)
      out << tag(:meta, property: 'copious:price', content: number_to_currency(listing.price))
      out << tag(:meta, property: 'copious:condition', content: listing.condition)
      if listing.size
        out << tag(:meta, property: 'copious:size', content: listing.size.name)
      end
      if listing.brand
        out << tag(:meta, property: 'copious:brand', content: listing.brand.name)
      end
      out << tag(:meta, property: 'copious:loves', content: likes_summary.count)
      if listing.seller.registered?
        out << tag(:meta, property: 'copious:seller', content: public_profile_url(listing.seller))
      end
      safe_join(out, "\n")
    end
  end

  def listing_create_banner(options = {})
    promo_banner(Brooklyn::Application.config.banners.create_listing, options)
  end

  # Sanitization for listing comments
  def comment_clean(comment, commenter, html_options = {})
    simple_format(comment_sanitize_and_convert(comment, commenter), html_options, sanitize: false).html_safe
  end

  def comment_sanitize_and_convert(comment, commenter)
    parsed_text = Nokogiri::HTML::fragment(comment.text)
    parsed_text.css('*').each do |node|
      if node.name == 'span' && node['data-role'] == 'kw'
        convert_keyword_node(comment, commenter, node, parsed_text)
      else
        node.swap(Nokogiri::XML::Text.new(node.content, parsed_text))
      end
    end
    parsed_text.to_html.html_safe
  end

  def convert_keyword_node(comment, commenter, node, doc)
    id = node['data-kw-id']
    slug = node['data-kw-slug']
    name = node['data-kw-name']
    type = node['data-kw-type']
    content = node.content

    # Create new nodes so we don't have to worry about removing nodes or unused attribtues
    if name.blank?
      new_node = Nokogiri::XML::Text.new(node.content, doc)
    elsif type.blank?
      new_node = Nokogiri::XML::Text.new(name, doc)
    else
      if type == 'tag'
        new_node = Nokogiri::XML::Node.new('a', doc)
        # Tag id is the slug
        new_node['href'] = browse_for_sale_path(id) unless id.blank?
        # XXX: mixpanel.track_links doesn't seem to work with a data-role selector
        new_node['class'] = 'hashtag-link'
        new_node['data-tag-slug'] = id
      elsif type == 'cf'
        new_node = Nokogiri::XML::Node.new('a', doc)
        new_node['href'] = public_profile_path(slug) unless slug.blank?
        new_node['class'] = 'mention-link'
        new_node['data-mentionee-slug'] = slug
        new_node['data-mentioner-slug'] = commenter ? commenter.slug : nil
      else # type == 'fb'
        new_node = Nokogiri::XML::Node.new('span', doc)
      end
      new_node['data-user-slug'] = current_user.slug if logged_in?
      new_node.content = content
    end

    node.swap(new_node)
  end

  def listing_stats(likes, saves, options = {})
    return nil unless likes > 0 || saves > 0
    content_tag(:span, data: {role: 'listing-stats'}) do
      out = []
      out << t('listings.product_card.stats.loves', count: likes) if likes > 0
      out << t('listings.product_card.stats.saves', count: saves) if saves > 0
      bar_separated(*out)
    end
  end

  # used to be user_card
  def listing_listed_by(user, viewer)
    out = []

    # photo and name
    out << content_tag(:div, :id => 'listed_by_profile') do
      out2 = []
      out2 << user_avatar_medium(user, class: 'text-adjacent')
      if user.guest?
        out2 << t(".listed_by.guest")
      else
        out2 << link_to_user_profile(user, id: 'listed_by_name')
      end
      if user.registered?
        out2 << tag(:br)
        out2 << content_tag(:span, class: 'joined') do
          t(".listed_by.joined_on", date: date(user.registered_at))
        end
      end
      safe_join(out2)
    end

    if user.registered?
      # edit profile or follow/unfollow button
      if logged_in?
        if user == viewer
          out << bootstrap_button(t(".listed_by.edit_profile_button"), settings_profile_path, class: 'edit-profile')
        else
          out << content_tag(:div, class: 'pull-left') do
            follow_control(user, viewer, follower_count_selector: "#listed-by-seller-followers-count-#{user.id}")
          end
        end
      end

      # biography
      if user.bio.present?
        out << content_tag(:div, id: "listed-by-bio-#{user.id}", class: 'clear margin-top pull-left listed-by-bio',
                           data: {role: 'bio'}) do
          out2 = []
          out2 << content_tag(:div, id: "listed-by-bio-truncated-#{user.id}", data: {role: 'excerpt-truncated'}) do
            sanitize(user.bio, tags: [])
          end
          out2 << link_to(t(".listed_by.bio.more"), "#listed-by-bio-full-#{user.id}",
                          data: {toggle: 'excerpt', text: "#listed-by-bio-truncated-#{user.id}"})
          out2 << content_tag(:div, id: "listed-by-bio-full-#{user.id}", data: {role: 'excerpt-full'},
                              style: 'display:none') do
            sanitize(user.bio, tags: [])
          end
          out2 << link_to(t(".listed_by.bio.less"), "#listed-by-bio-truncated-#{user.id}", style: 'display:none',
                          data: {toggle: 'excerpt', text: "#listed-by-bio-full-#{user.id}"})
          safe_join(out2)
        end
      end

      # feedback
      if feature_enabled?(:feedback)
        out << content_tag(:div) do
          feedback_summary(user, without_break: true)
        end
      end

      # connected networks - if FB is connected, show that as the primary network and show its connection count inline,
      # otherwise if Twitter is connected use that as the primary. all others are secondary and show their connection
      # counts in tooltips.
      unless Brooklyn::Application.config.networks.hidden_for_users.include?(user.slug)
        out << content_tag(:ul, class: 'connected-network-list') do
          out2 = []
          profiles = user.person.connected_profiles
          facebook = profiles.detect { |p| p.network == Network::Facebook.symbol && p.type.nil? }
          if facebook
            profiles.delete(facebook)
            out2 << content_tag(:li) do
              link_to_network_icon(facebook.network, facebook) +
              t(".listed_by.profiles.facebook_html", count: facebook.connection_count)
            end
          else
            twitter = profiles.detect { |p| p.network == Network::Twitter.symbol }
            if twitter
              profiles.delete(twitter)
              out2 << content_tag(:li) do
                link_to_network_icon(twitter.network, twitter) +
                t(".listed_by.profiles.twitter_html", count: twitter.connection_count)
              end
            end
          end
          profiles = profiles.sort_by do |profile|
            case profile.network
            when Network::Facebook.symbol then -1
            when Network::Twitter.symbol then -2
            when Network::Tumblr.symbol then -3
            when Network::Instagram.symbol then -4
            else -10
            end
          end
          profiles.each do |profile|
            network = profile.type ? "#{profile.network}_#{profile.type}".to_sym : profile.network
            tooltip = t(".listed_by.profiles.#{network}_html", count: profile.connection_count)
            out2 << content_tag(:li, rel: 'tooltip', title: tooltip, data: {html: true}) do
              link_to_network_icon(profile.network, profile)
            end
          end
          safe_join(out2)
        end
      end
    end

    # listing, love and follower counts
    out << content_tag(:ul, id: 'listed-by-stats-container') do
      out2 = []
      # Listings
      out2 << content_tag(:li) do
        if user.registered?
          link_to public_profile_path(user) do
            content_tag(:span, user.visible_listings_count, id: "listed-by-seller-listings-count-#{user.id}",
                        class: 'listed-by-stats') +
            content_tag(:span, "Listings", class: "listed-by-stats-header")
          end
        else
          content_tag(:span, 0, id: "listed-by-seller-listings-count-#{user.id}", class: 'listed-by-stats') +
          content_tag(:span, "Listings", class: "listed-by-stats-header")
        end
      end
      # Loves
      out2 << content_tag(:li) do
        if user.registered?
          link_to liked_public_profile_path(user) do
            content_tag(:span, user.likes_count, id: "listed-by-seller-loves-count-#{user.id}",
                        class: 'listed-by-stats') +
            content_tag(:span, t('listings.show.listed_by.loves', count: user.likes_count), class: "listed-by-stats-header")
          end
        else
          content_tag(:span, 0, id: "listed-by-seller-loves-count-#{user.id}", class: 'listed-by-stats') +
          content_tag(:span, t('listings.show.listed_by.loves', count: user.likes_count), class: "listed-by-stats-header")
        end
      end
      # Followers
      out2 << content_tag(:li) do
        if user.registered?
          link_to followers_public_profile_path(user) do
            content_tag(:span, user.registered_follows.total_count,
                        id: "listed-by-seller-followers-count-#{user.id}", class: 'listed-by-stats') +
            content_tag(:span, "Followers", class: "listed-by-stats-header")
          end
        else
          content_tag(:span, 0, id: "listed-by-seller-followers-count-#{user.id}", class: 'listed-by-stats') +
          content_tag(:span, "Followers", class: "listed-by-stats-header")
        end
      end
      safe_join(out2)
    end

    content_tag(:div, safe_join(out), data: {role: 'listed-by'})
  end
end
