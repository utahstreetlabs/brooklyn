# encoding: utf-8
module Listings
  module ModalHelper
    def listing_modal(modal)
      content_tag(:div, data: {source: 'listing-modal'}) do
        out = []
        out << listing_modal_top(modal)
        out << listing_modal_footer(modal)
        safe_join(out)
      end
    end

    # The listing modal is composed of the "top" (body + header) and "footer". When a thumbnail
    # in the footer is selected, the top is updated with new content, but the carousel in the footer
    # is not changed.
    def listing_modal_top(modal)
      content_tag(:div, data: {role: 'listing-modal-top'}, class: 'listing-modal-top') do
        listing_modal_body(modal)
      end
    end

    def listing_modal_header(modal)
      content_tag(:div, class: 'listing-modal-header') do
        out = []
        out << user_avatar_xsmall(modal.seller, class: 'text-adjacent')
        out << content_tag(:div, class: 'listing-creator-info') do
          out2 = []
          out2 << link_to_user_profile(modal.seller, class: 'listing-creator-name')
          out2 << listing_modal_header_story(modal)
          safe_join(out2)
        end
        out << content_tag(:div, class: 'listing-creator-follow') do
          listing_modal_header_cta_button(modal) if modal.viewer
        end
        safe_join(out)
      end
    end

    def listing_modal_body(modal)
      content_tag(:div, data: {role: 'listing-modal-body'}) do
        out = []
        out << listing_modal_navigation(modal)
        out << listing_modal_cover_photo(modal)
        out << content_tag(:div, class: 'listing-modal-body-content scrollable') do
          out2 = []
          out2 << listing_modal_header(modal)
          out2 << listing_modal_info(modal)
          out2 << content_tag(:div, class: 'well kill-margin-bottom') do
            out3 = []
            # not used for v1.1
            #out3 << listing_modal_social(modal)
            out3 << listing_modal_comments(modal)
            safe_join(out3)
          end
          safe_join(out2)
        end
        safe_join(out)
      end
    end

    # The footer contains the carousel containing thumbnails from other listings.
    def listing_modal_footer(modal)
      content_tag(:div, data: {role: 'listing-modal-footer'}, class: 'listing-modal-footer') do
        out = []
        out << listing_modal_thumbnail_carousel(modal)
        out << listing_modal_footer_caption(modal)
        out << listing_modal_footer_cta_button(modal) if modal.viewer
        safe_join(out)
      end
    end

    def listing_modal_header_story(modal)
      collection_link = listing_modal_header_collection_link(modal) if modal.collection
      # timestamp will not be used for v2 of listing modal, but let's preserve it as it will come back soon
      timestamp = listing_modal_header_timestamp(modal)
      if modal.external?
        to_name = collection_link ?
          raw(t('listing_modal.header.listing_source.external.to_name', name: collection_link)) : nil
        t('listing_modal.header.listing_source.external.story_notimestamp_html', to_name: to_name, domain: modal.domain)
      else
        name_on = collection_link ?
          raw(t('listing_modal.header.listing_source.internal.name_on', name: collection_link)) : nil
        t('listing_modal.header.listing_source.internal.story_notimestamp_html', name_on: name_on)
      end
    end

    def listing_modal_header_collection_link(modal)
      link_to(modal.collection.name, public_profile_collection_path(modal.collection_owner, modal.collection),
              class: 'listing-collection-link ellipsis')
    end

    def listing_modal_header_timestamp(modal)
      content_tag(:span, class: 'timestamp') do
        out = []
        out << content_tag(:span, '', class: 'icons-timestamp')
        out << t('listing_modal.header.timestamp', timestamp: time_ago_in_words(modal.created_at))
        safe_join(out)
      end
    end

    def listing_modal_header_cta_button(modal)
      follow_control(modal.seller, modal.viewer, class: 'btn-small', no_text: true)
    end

    def listing_modal_navigation(modal)
      content_tag(:div, data: {role: 'listing-modal-navigation'}, class: 'listing-modal-navigation-container') do
        out = []
        out << link_to('‹', nilhref, class: 'carousel-control left', data: {slide: 'prev', action: 'navigate'})
        out << link_to('›', nilhref, class: 'carousel-control right', data: {slide: 'next', action: 'navigate'})
        safe_join(out)
      end
    end

    def listing_modal_thumbnail_carousel(modal)
      content_tag(:div, data: {role: 'listing-modal-thumbnails'}) do
        listing_thumbnail_photos(modal.listing, modal.thumbnail_photos, count: modal.thumbnail_count, navigation: false,
                                 total_count: modal.thumbnail_max) do |photo, index|
          options = {data: {role: 'thumbnail-wrapper'}}
          options[:class] = 'selected' if photo.listing_id == modal.id
          content_tag(:li, options) do
            data = {
              photo: photo.id,
              role: 'thumbnail',
              index: index,
              url: listing_modal_top_path(modal.thumbnail_listing(photo.listing_id)),
            }
            data[:collection] = modal.collection_id if modal.collection
            listing_photo_tag(photo, :px_100x100, id: "thumbnail-#{photo.id}", width: 100, height: 100, data: data)
          end
        end
      end
    end

    def listing_modal_footer_caption(modal)
      content_tag(:h2, class: 'sub-header ellipsis') do
        out = []
        if modal.collection
          out << raw(t('listing_modal.footer.more_from_collection',
                       collection: listing_modal_header_collection_link(modal)))
          out << raw(t('listing_modal.footer.by_username',
                       name: link_to_user_profile(modal.seller, class: 'collection-creator-name')))
        else
          out << raw(t('listing_modal.footer.more_from_user',
                       name: link_to_user_profile(modal.seller, class: 'collection-creator-name')))
        end
        safe_join(out)
      end
    end

    def listing_modal_footer_cta_button(modal)
      content_tag(:div, class: 'collection-creator-follow') do
        if modal.collection
          collection_follow_button(modal.collection, modal.following_collection?)
        else
          follow_control(modal.seller, modal.viewer, class: 'btn-small')
        end
      end
    end

    def listing_modal_cover_photo(modal)
      content_tag(:div, class: 'listing-modal-body-photo') do
        out = []
        out << content_tag(:div, class: 'listing-photos') do
          out2 = []
          out2 << link_to(listing_modal_listing_path(modal, internal: true),
            target: listing_modal_listing_link_target(modal), data: { history: 'redirect' }) do
            listing_photo_tag(modal.primary_photo, :px_460x460)
          end
          safe_join(out2)
        end
        safe_join(out)
      end
    end

    def listing_modal_info(modal)
      content_tag(:div, class: 'product-info listing-modal') do
        out = []
        out << link_to(listing_modal_listing_path(modal), target: listing_modal_listing_link_target(modal),
                       data: {history: 'redirect'}) do
          content_tag(:span, modal.title, class: 'product-title')
        end
        out << listing_modal_description(modal)
        # not used for v1.1
        #out << listing_modal_price_box(modal)
        out << listing_modal_ctas(modal)
        safe_join(out)
      end
    end

    def listing_modal_description(modal)
      content_tag(:div, id: 'description', class: 'product-description-container', data: {role: 'excerpt'}) do
        out = []
        out << content_tag(:div, id: 'description-truncated', data: {role: 'excerpt-truncated'}) do
          out2 = []
          out2 << sanitize_wysiwig(modal.description)
          out2 << link_to(t("listing_modal.description.more"), "#description-full",
                          data: {toggle: 'excerpt', text: "#description-truncated"})
          safe_join(out2)
        end
        out << content_tag(:div, id: 'description-full', data: {role: 'excerpt-full'}, style: 'display:none') do
          out3 = []
          out3 << sanitize_wysiwig(modal.description)
          out3 << link_to(t("listing_modal.description.less"), '#description-truncated', style: 'display:none',
                          data: {toggle: 'excerpt', text: '#description-full'})
          safe_join(out3)
        end
        safe_join(out)
      end
    end

    def listing_modal_price_box(modal)
      content_tag(:div, class: 'price-box listing-modal') do
        out = []
        out << content_tag(:div, class: 'price') do
          out2 = []
          if modal.supports_original_price? && modal.original_price?
            out2 << content_tag(:span, number_to_currency(modal.original_price), class: 'original-price')
          end
          safe_join(out2)
        end
        # not used for v1.1
        #if modal.supports_shipping? && !modal.free_shipping?
        #  out2 << "+ #{number_to_currency(modal.shipping)} Shipping"
        #end
        safe_join(out, ' ')
      end
    end

    def listing_modal_ctas(modal)
      content_tag(:ul, class: 'listing-modal-ctas', data: {role: 'ctas'}) do
        if modal.viewer
          out = []
          out << content_tag(:li, data: {listing: modal.id}, class: 'stats-button-container') do
            out2 = []
            out2 << content_tag(:div, class: 'stats-balloon') do
              content_tag(:span, modal.likes_count)
            end
            out2 << listing_love_button(modal.listing, modal.likes_listing?, class: 'stats-button btn-primary',
                                        like_url: listing_modal_like_path(modal.listing),
                                        unlike_url: listing_modal_like_path(modal.listing))
            safe_join(out2)
          end
          out << content_tag(:li, data: {listing: modal.id}, class: 'stats-button-container save-button-container') do
            out3 = []
            out3 << content_tag(:div, class: 'stats-balloon') do
              content_tag(:span, modal.saves_count)
            end
            out3 << save_listing_to_collection_button(modal.listing, modal.saved_listing?, photo: modal.primary_photo,
                                                      source: 'listing_modal')
            safe_join(out3)
          end
          out << content_tag(:li, data: {listing: modal.id}, class: 'stats-button-container') do
            out4 = []
            out4 << content_tag(:div, class: 'stats-balloon') do
              content_tag(:span, number_to_currency(modal.price))
            end
            if modal.sold?
              out4 << content_tag(:div, class: 'sold-button stats-button') do
                t('listing_modal.button.sold')
              end
            else
              url = listing_modal_listing_path(modal)
              out4 << bootstrap_button(url, target: listing_modal_listing_link_target(modal), id: 'buy-button',
                                       data: {history: 'redirect'}, class: 'stats-button transactional') do
                out5 = []
                out5 << content_tag(:span, '', class: 'icons-button-shop')
                out5 << t('listing_modal.button.shop')
                safe_join(out5)
              end
            end
            safe_join(out4)
          end
          safe_join(out)
        end
      end
    end

    # not used for v1.1
    def listing_modal_social(modal)
      content_tag(:div, class: 'well-header well-header-small feed-story listing-modal') do
        out = []
        out << listing_modal_social_story(modal)
        out << listing_share_box(modal, modal.primary_photo)
        safe_join(out, ' ')
      end
    end

    def listing_modal_social_story(modal)
      story = ListingStory.find_most_recent_for_listing(modal.id)
      listing_social_story(story, modal.likes_count, modal.saves_count) if story
    end

    def listing_modal_comments(modal)
      content_tag(:div, data: {role: 'comments'}, class: 'well-body') do
        out = []
        placeholder = if feature_enabled?('listings.comments.typeahead')
          t('listing_modal.comments.placeholder.typeahead_html')
        else
          t('listing_modal.comments.placeholder.default_html')
        end
        if modal.viewer
          out << content_tag(:div, class: 'well-header well-header-small') do
            out2 = []
            out2 << content_tag(:div, user_avatar_xsmall_nolink(modal.viewer), class: 'avatar text-adjacent')
            out2 << bootstrap_form_for(Anchor::Comment.new, as: :comment,
                                       url: listing_modal_comments_path(modal.listing),
                                       id: "listing-modal-comment-form-#{modal.id}", remote: true,
                                       html: {data: {include_source: true}}) do |f|
              f.text_area(:text, id: "listing-modal-comment-input-#{modal.id}", placeholder: placeholder,
                          disabled: !modal.commentable?, data: {control: 'commentbox'},
                          class: 'comment-text-input')
            end
            safe_join(out2)
          end
        else
          out << content_tag(:div, placeholder, class: 'faux-field-text-small')
        end
        if modal.any_comments?
          out << content_tag(:ul, class: 'comment-stream comment-stream-small comment-stream-scroll',
                             data: {role: 'comment-stream'}) do
            out2 = []
            out2 += modal.comments_to_show.map do |comment|
              commenter = modal.commenter(comment.user_id)
              if commenter
                content_tag(:li, id: "listing-modal-comment-#{comment.id}", class: 'comment-container') do
                  out3 = []
                  out3 << user_avatar_xsmall(commenter, class: 'text-adjacent')
                  out3 << content_tag(:div, class: 'comment-content-container') do
                    out4 = []
                    out4 << content_tag(:span, link_to_user_profile(commenter), class: 'commenter-name')
                    out4 << comment_clean(comment, commenter, class: 'comment-content')
                    out4 << content_tag(:span, class: 'timestamp') do
                      t('listing_modal.comments.timestamp', timestamp: time_ago_in_words(comment.created_at, true))
                    end
                    safe_join(out4)
                  end
                  safe_join(out3)
                end
              end
            end
            if modal.invisible_comments?
              # XXX: spec says new window, but that isn't consistent with other listing page links
              out2 << content_tag(:li, class: 'see-all-comments') do
                link_to(listing_path(modal.listing, anchor: 'feed'), data: { history: 'reload' }) do
                  t('listing_modal.comments.see_all', count: modal.total_comments)
                end
              end
            end
            safe_join(out2)
          end
        end
        safe_join(out)
      end
    end

    def listing_modal_listing_path(modal, options = {})
      useInternal = options.delete(:internal) || false
      if modal.external? && !useInternal
        external_listing_path(modal.listing, options)
      else
        listing_path(modal.listing, options)
      end
    end

    def listing_modal_listing_link_target(modal)
      'external' if modal.external?
    end
  end
end
