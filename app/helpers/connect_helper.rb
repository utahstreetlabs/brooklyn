module ConnectHelper
  def link_to_invite_facebook(options = {})
    options = {
      class: 'button primary large',
      data: {
        invite: 'facebook'
      }
    }.merge(options)
    link_to image_and_text("social_networks/facebook_32.png", "Invite friends with Facebook"), '#', options
  end

  def link_to_invite_email(options = {})
    options = {
      class: 'button primary large email',
      data: {
        invite: 'email'
      }
    }.merge(options)
    link_to image_and_text("icons/email-icon.jpg", "Email my friends"), '#', options
  end

  def untargeted_invite_url(user)
    invite_url(user.untargeted_invite_code)
  end

  def link_to_share_invite_facebook
    link_to image_and_text("social_networks/facebook_32.png", "Facebook"), signup_invites_share_path(:facebook),
            target: :_blank, class: 'button share facebook'
  end

  def link_to_share_invite_twitter
    link_to image_and_text("social_networks/twitter_32.png", "Twitter"), signup_invites_share_path(:twitter),
            target: :_blank, class: 'button share twitter'
  end

  def if_just_invited_friends(&block)
    invite_count = (flash[:invited] || params[:invited]).to_i
    yield invite_count if invite_count > 0
  end

  def invite_box(invite, invite_action)
    content_tag(:div, id: 'fb-friend-invite') do
      form_for(invite, as: :invite, url: invite_action) do |f|
        h = f.field(:message, container: :div) do
          f.text_area(:message, placeholder: 'Write a personal message')
        end
        h << f.buttons(save_text: 'Invite', data: {action: 'invite'})
        h
      end
    end
  end

  def who_to_follow_user_strip(strip)
    user = strip.user
    content_tag(:li, data: {role: "user-strip"}, id: "user-strip-#{user.id}", class: 'user-strip') do
      content_tag(:div, class: 'pull-left') do
        content_tag(:div, class: 'avatar-container pull-left hidden-phone') do
          user_avatar_small(user, class: 'text-adjacent')
        end +
        content_tag(:div, class: 'avatar-container pull-left hidden-desktop') do
          user_avatar_xsmall(user, class: 'text-adjacent')
        end +
        content_tag(:div, class: 'pull-left') do
          content_tag(:h4, class: 'ellipsis') do
            user.name
          end +
          profile_user_strip_stats(strip, class: "hidden-phone")
        end
      end +
      content_tag(:div, class: 'pull-right') do
        content_tag(:div, class: "hidden-phone") do
          profile_user_strip_follow_button(strip, user, current_user) +
          link_to("", follow_suggestion_path(user.id), {class: "close-button", data: {action: "remove", method: "DELETE", remote: "true", target: "user-strip-#{user.id}" }, title: "Hide" })
        end +
        who_to_follow_user_strip_listing_photos(strip)
      end +
      content_tag(:div, class: 'hidden-desktop') do
        profile_user_strip_stats(strip, {hide_followers: true, hide_labels: true}) +
        profile_user_strip_follow_button(strip, user, current_user, {class: "pull-right"})
      end
    end
  end

  def who_to_follow_user_strip_listing_photos(strip)
    content_tag(:ul, :class => 'pull-left thumbnails') do
      out = []
      strip.photos.each.with_index do |photo, i|
        out << content_tag(:li) do
          link_to(listing_photo_tag(photo, :medium), listing_path(strip.listings[i], src: "wtf-#{strip.user.slug}"),
                  class: 'thumbnail')
        end
      end
      safe_join(out)
    end
  end
end
