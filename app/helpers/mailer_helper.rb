# Helper functions for generating email content. Note that mailers do not have access to any other app helpers, only
# the built in ActionPack ones, so these helper methods must follow that same restriction.
module MailerHelper
  def mailer_graf(options = {}, &block)
    content_tag :p, class: 'bodyText', style: "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 14px; line-height: 20px; font-weight: 400; color: #555555; margin-top: 0px; margin-bottom: 14px; #{options[:styles]}", &block
  end

  def mailer_quote(&block)
    text = mailer_format_html(capture { yield })
    content_tag :blockquote, style: 'margin:1em 0em;padding:1em;border-left:2px solid #29BFD3;' do
      content_tag :p, text, class: 'bodyText', style: "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 14px; line-height: 20px; font-weight: 400; color: #555555; margin: 0px;"
    end
  end

  def mailer_header(&block)
    content_tag :p, class: 'header', style: "font-size: 33px; line-height: 37px; font-weight: 300; font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; color: #333333; display: block; text-align: left; width: 100%; margin-top: 10px; margin-bottom: 16px; margin-left: 0px; margin-right: 0px; ", &block
  end

  def mailer_subheader(&block)
    content_tag :p, class: 'subHeader', style: "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 16px; line-height: 22px; font-weight: 600; margin-top: 16px; margin-bottom: 16px; margin-left: 0px; margin-right: 0px; ", &block
  end

  def mailer_bold(options = {}, &block)
    content_tag :span, class: 'bodyText', style: "font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; font-size: 14px; line-height: 20px; font-weight: 600; color: #555555; margin: 0px; display: inline; #{options[:styles]}", &block
  end

  def mailer_image_url(url)
    url =~ /^\/\// ? "http:#{url}" : url
  end

  def mailer_image_tag(url, options = {})
    options = options.reverse_merge(alt: '')
    image_tag(mailer_image_url(url), options)
  end

  def mailer_link_to(*args, &block)
    options = args.extract_options!
    text = args.shift if args.length > 1
    url = rewrite_mailer_url(args.shift)
    # these links tend to be really long, so get the opening tag in its own line
    text = "\n".html_safe + (text.present? ? text : block.call)
    "\n".html_safe + link_to(text, url, options)
  end

  def mailer_user_profile_photo(user)
    mailer_link_to(mailer_image_tag(user.profile_photo.url(:px_70x70), height: 70, width: 70, alt: user.name),
                   public_profile_url(user))
  end

  def mailer_mail_to(address, name = nil, options = {}, &block)
    mail_to address, name, options, &block
  end

  def mailer_button(text, url, options = {}, &block)
    content_tag :span, style: "text-decoration: none !important; background-color: #29bfd3; padding-top: 1px; padding-right: 0px; padding-bottom: 1px; padding-left: 0px; margin-top: 20px; border-style: solid; border-width: 1px; border-top-color: #77c6d0; border-right-color: #77c6d0; border-bottom-color: #009aae; border-left-color: #79c6d0; border-collapse: separate !important; display: inline-block;margin-bottom: 10px; #{options[:styles]}", class: 'mailer-button'  do
      style = "display: inline; font-size: 14px; font-weight: 400; background-color: #29bfd3; color: white !important; padding-top: 5px; padding-bottom: 5px; padding-left: 12px; padding-right: 12px; line-height: 25px; text-shadow: 0 1px 1px #888888; border-collapse: separate !important; text-decoration: none !important;"
      url = rewrite_mailer_url url
      options = options.merge(style: style)
      link_to text, url, options, &block
    end
  end

  def rewrite_mailer_url(url)
    if @link_params and @link_params.any?
      sep = url =~ /\?/ ? '&' : '?'
      qs = @link_params.inject([]) {|m, kv| m << "#{URI.escape(kv[0])}=#{URI.escape(kv[1])}"}.join('&')
      "#{url}#{sep}#{qs}"
    else
      url
    end
  end

  # sanitizes and formats user text for inclusion in an html email. converts single newlines to <br> but does not
  # convert double newlines to <p>.
  def mailer_format_html(html)
    html = '' if html.nil?
    html = mailer_sanitize_comment(html, tags: [])
    html = html.to_str
    html.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
    html.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
    html.html_safe
  end

  def mailer_format_text(text)
    text ||= ''
    # Sanitize text to remove any HTML microformatting
    block_format sanitize(text, tags: [])
  end

  def mailer_sanitize_comment(html, options = {})
    sanitize(html, options)
  end

  def mailer_follow_button(followee, follower, options = {})
    if not follower.following?(followee)
      mailer_button "Follow #{followee.name}", public_profile_follow_url(followee), options
    elsif followee.seller_listings.active.any?
      mailer_button "View #{followee.name}'s listings", public_profile_url(followee)
    elsif followee.likes_count > 0
      mailer_button "Browse #{followee.name}'s loves", liked_public_profile_url(followee)
    else
      mailer_button "See who #{followee.name} is following", following_public_profile_url(followee)
    end
  end

  def follow_text(followee, follower)
    "Follow #{followee.name.html_safe} at #{rewrite_mailer_url public_profile_url(followee)}" unless follower.following?(followee)
  end

  def mailer_order_details_tracking_number(order, options = {})
    out = []
    if options[:tracking_number].respond_to?(:[]) && options[:tracking_number][:updated]
      out << content_tag(:strong, 'Updated')
    end
    out << 'Tracking Number:'
    out << link_to(tracking_url(order)) do
      safe_join([order.shipment.carrier.name, order.shipment.tracking_number], ' ')
    end
    safe_join(out, ' ')
  end

  def mailer_order_details_tracking_number_text(order, options = {})
    out = []
    if options[:tracking_number].respond_to?(:[]) && options[:tracking_number][:updated]
      out << '**Updated**'
    end
    out << 'Tracking Number:'
    out += [order.shipment.carrier.name, order.shipment.tracking_number, tracking_url(order)]
    safe_join(out, ' ')
  end

  def responsive_content_table(sections, options = {})
    td_opts = {width: '100%', align: 'center'}.merge(options.delete(:td_opts) || {})
    options = {width: 560, id: 'content-area', style: 'margin-bottom: 0px; margin-left: 0px; margin-right: 0px;', align: 'center', 'border-spacing' => 0}.merge(options)
    content_tag :table, options do
      sections.map do |section|
        out = ["\n"]
        out << content_tag(:tr, content_tag(:td, section.first, td_opts.merge(:class => 'header-cell')))
        out += section[1..-1].map do |item|
          content_tag(:tr, content_tag(:td, item, td_opts))
        end
        out.join("\n").html_safe
      end.join("\n").html_safe
    end
  end

  def responsive_header(text)
    style = "font-size: 25px; line-height: 37px; font-weight: 100; font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; color: black !important; display: block; text-align: left; width: 535px; padding-left: 0px; margin-top: 0px; margin-bottom: 16px;"
    content_tag(:h1, text, :class => 'header', style: style)
  end

  def responsive_mailer_button(text, url, options = {}, &block)
    url = rewrite_mailer_url url
    link_style = "text-decoration: none !important; float: right; background-color: #F0F0F0; padding: 0px; margin-top: 0px; border-style: solid; border-width: 1px; border-top-color: #E9E9E9; border-right-color: #E6E6E6; border-bottom-color: #CDCDCD; border-left-color: #E6E6E6;"
    link_options = {style: link_style}
    span_style = "display: inline; float: right; font-size: 15px; font-weight: normal; background-color: #F0F0F0; color: #333333; padding-top: 2px; padding-bottom: 2px; padding-left: 10px; padding-right: 10px; line-height: 25px; border-width: 1px; border-style: solid; border-top-color: #FBFBFB; border-right-color: #FBFBFB; border-bottom-color: #FBFBFB; border-left-color: #FBFBFB; font-family: 'Helvetica Neue', 'Helvetica', 'Arial', sans-serif; border-collapse: collapse; text-decoration: none !important;"
    span_options = {style: span_style}.merge(options)
    # links are crazy long, and cause SMTP spec violations, so add an extra \n
    span = "\n".html_safe + content_tag(:span, text, span_options)
    link_to span, url, link_options, &block
  end

  def footer_content(options={})
    t = <<-EOF
Copious | 164 Townsend St #6, San Francisco, CA 94107<br />
To ensure delivery to your inbox, add no-reply@copious.com to your address book.
#{options[:email_settings_link] || email_settings}
EOF
    t.html_safe
  end

  def email_settings
    "Change your email #{mailer_link_to 'settings', settings_email_url}."
  end

  ##
  ## NEW MAILER LAYOUT
  ##

  # @option options [Hash] :link_styles CSS rules to include in the +style+ attribute of the link'
  # @option options [Hash] :text_styles CSS rules to include in the +style+ attribute of the link's text span
  def mailer_header_link_to(text, url, options = {}, &block)
    options = options.dup
    link_styles = (options.delete(:link_styles) || {}).reverse_merge(
      :'text-decoration'   => 'none',
    )
    mailer_link_to(url, options.merge(style: style_attribute(link_styles))) do
      text_styles = (options.delete(:text_styles) || {}).reverse_merge(
        :'font-weight'     => '400',
        :'text-align'      => 'left',
        :'text-decoration' => 'none',
        :'font-size'       => '14px',
        :color             => '#799DD3'
      )
      content_tag(:span, (text || block.call), style: style_attribute(text_styles))
    end
  end

  # @option options [Hash] :container_styles CSS rules to include in the +style+ attribute of the container element
  # @option options [Hash] :user_styles CSS rules to include in the +style+ attribute of the user photo
  # @option options [Hash] :action_styles CSS rules to include in the +style+ attribute of the action image
  # @option options [Hash] :listing_styles CSS rules to include in the +style+ attribute of the listing photo
  def mailer_user_listing_social_action(user, action, listing, options = {})
    container_styles = options.fetch(:container_styles, {}).reverse_merge(
      :display      => 'block',
      :'text-align' => 'center',
      :margin       => '16px 0px 16px 0px',
      :padding       => '0px 25px'
    )
    content_tag(:div, class: 'avatar-container', style: style_attribute(container_styles)) do
      content_tag(:table, id: 'social-action-box', cellpadding: 0, cellspacing: 0, border: 0, width: 210, height: 70,
                  :'border-spacing' => 0, style: 'display: inline-block;') do
        content_tag(:tr) do
          content_tag(:td, width: 210, height: 70) do
            out = []
            user_styles = options.fetch(:user_styles, {}).reverse_merge(
              :display        => 'inline-block',
              :'border-style' => 'none',
              :width          => '70px',
              :height         => '70px',
              :float          => 'left',
              :'background-color' => '#868686'
            )
            out << mailer_image_tag(user.profile_photo.url(:px_70x70), alt: user.name,
                                    style: style_attribute(user_styles))
            action_styles = options.fetch(:action_styles, {}).reverse_merge(
              :display        => 'inline-block',
              :'border-style' => 'none',
              :width          => '70px',
              :height         => '70px',
              :float          => 'left'
            )
            out << mailer_image_tag("icons/emails/#{action.to_s.capitalize}Icon.png",
                                    style: style_attribute(action_styles),
                                    alt: t("shared_mailer.social_action.icon.#{action}"))
            listing_styles = options.fetch(:listing_styles, {}).reverse_merge(
              :display        => 'inline-block',
              :'border-style' => 'none',
              :width          => '70px',
              :height         => '70px',
              :float          => 'left',
              :'background-color' => '#868686'
            )
            out << mailer_image_tag(listing.photos.first.version_url(:small),
                                    alt: options.fetch(:collection_name, listing.title),
                                    style: style_attribute(listing_styles))
            safe_join(out, "\n")
          end
        end
      end
    end
  end

  # @option options [Boolean] :with_photo (false) whether or not to show the user's photo
  # @option options [Hash] :container_styles CSS rules to include in the +style+ attribute of the container element
  # @option options [Hash] :photo_styles CSS rules to include in the +style+ attribute of the photo image tag
  # @option options [Hash] :name_styles CSS rules to include in the +style+ attribute of the user name element
  # @option options [Hash] :bio_styles CSS rules to include in the +style+ attribute of the bio element
  def mailer_user_info(user, options = {})
    container_styles = options.fetch(:container_styles, {}).reverse_merge(
      :display      => 'block',
      :'text-align' => 'center'
    )
    content_tag(:div, class: 'actioner-info-container', style: style_attribute(container_styles)) do
      out = []
      if options.fetch(:with_photo, false)
        photo_styles = options.fetch(:photo_styles, {}).reverse_merge(
          :'margin'  => '16px 0px 16px 0px',
          :'background-color' => '#868686'
        )
        out << mailer_image_tag(user_profile_photo_url(user, 150, 150), height: 150, width: 150, alt: user.name,
                                style: style_attribute(photo_styles))
      end
      name_styles = options.fetch(:name_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '18px',
        :'line-height'   => '20px',
        :'font-weight'   => '600',
        :color           => '#1D1D1B',
        :display         => 'block',
        :'text-align'    => 'center',
        :'margin-bottom' => '16px'
      )
      out << content_tag(:span, class: 'actioner-name', style: style_attribute(name_styles)) do
        user.name
      end
      if user.bio.present?
        bio_styles = options.fetch(:bio_styles, {}).reverse_merge(
          :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
          :'font-size'     => '12px',
          :'line-height'   => '18px',
          :'font-weight'   => '300',
          :color           => '#6F6F6E',
          :display         => 'inline-block',
          :'text-align'    => 'center',
          :width           => '430px',
          :'margin-bottom' => '16px'
        )
        out << content_tag(:span, class: 'body-text', style: style_attribute(bio_styles)) do
          user.bio
        end
      end
      safe_join(out, "\n")
    end
  end

  # @option options [Hash] :container_styles CSS rules to include in the +style+ attribute of the container element
  # @option options [Hash] :stats_styles CSS rules to include in the +style+ attribute of the stats elements
  # @option options [Hash] :stats_header_styles CSS rules to include in the +style+ attribute of the stats header
  #   elements
  # @option options [Hash] :listing_styles CSS rules to include in the +style+ attribute of the listing photo
  def mailer_user_stats_and_listings(user, listing_infos, options = {})
    container_styles = options.fetch(:container_styles, {}).reverse_merge(
      :display         => 'inline-block',
      :'text-align'    => 'center',
      :width           =>  '430px',
      :'border-width'  => '1px 0px 1px 0px',
      :'border-style'  => 'solid',
      :'border-color'  => '#C6C6C5',
      :padding         => '13px 0px 13px 0px',
      :'margin-bottom' => '10px'
    )
    content_tag(:div, class: 'actioner-stats-container', style: style_attribute(container_styles)) do
      out = []
      out << content_tag(:table, id: 'actioner-stats', cellpadding: 0, cellspacing: 0, border: 0, width: 310,
                         height: 40, :'border-spacing' => 0, style: 'margin: 0px 55px 16px 55px;') do
        content_tag(:tr) do
          out2 = []
          stats_styles = options.fetch(:stats_styles, {}).reverse_merge(
            :'font-family'    => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
            :'font-size'      => '18px',
            :'line-height'    => '18px',
            :'font-weight'    => '500',
            :color            => '#799DD3',
            :display          => 'block',
            :'text-align'     => 'center',
            :'text-decoration'=> 'none',
            :'margin-bottom'  => '6px'
          )
          stats_header_styles = options.fetch(:stats_header_styles, {}).reverse_merge(
            :'font-family'    => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
            :'font-size'      => '11px',
            :'line-height'    => '13px',
            :'font-weight'    => '300',
            :color            => '#6F6F6E',
            :display          => 'block',
            :'text-align'     => 'center',
            :'text-transform' => 'uppercase'
          )
          out2 << content_tag(:td) do
            mailer_link_to(public_profile_url(user), style: 'border: none; text-decoration: none;') do
              out3 = []
              out3 << content_tag(:span, user.visible_listings_count, class: 'actioner-stats',
                                  style: style_attribute(stats_styles))
              out3 << content_tag(:span, class: 'actioner-stats-header', style: style_attribute(stats_header_styles)) do
                t('shared_mailer.stats.header.listings')
              end
              safe_join(out3, "\n")
            end
          end
          out2 << content_tag(:td) do
            mailer_link_to(liked_public_profile_url(user), style: 'border: none; text-decoration: none;') do
              out3 = []
              out3 << content_tag(:span, user.likes_count, class: 'actioner-stats',
                                  style: style_attribute(stats_styles))
              out3 << content_tag(:span, class: 'actioner-stats-header', style: style_attribute(stats_header_styles)) do
                t('shared_mailer.stats.header.loves')
              end
              safe_join(out3, "\n")
            end
          end
          out2 << content_tag(:td) do
            mailer_link_to(followers_public_profile_url(user), style: 'border: none; text-decoration: none;') do
              out3 = []
              out3 << content_tag(:span, user.registered_followers.total_count, class: 'actioner-stats',
                                  style: style_attribute(stats_styles))
              out3 << content_tag(:span, class: 'actioner-stats-header', style: style_attribute(stats_header_styles)) do
                t('shared_mailer.stats.header.followers')
              end
              safe_join(out3, "\n")
            end
          end
          safe_join(out2, "\n")
        end
      end
      if listing_infos.any?
        out << content_tag(:table, id: 'actioner-activities', cellpadding: 0, cellspacing: 0, border: 0, width: 320,
                           height: 70, :'border-spacing' => 0, style: 'margin: 0px 55px 5px 55px;') do
          content_tag(:tr) do
            out2 = []
            listing_styles = options.fetch(:listing_styles, {}).reverse_merge(
              :display            => 'block',
              :'border-style'     => 'none',
              :width              => '70px',
              :height             => '70px',
              :'background-color' => '#868686',
            )
            listing_infos.each do |info|
              out2 << content_tag(:td, style: 'width: 70px; height: 70px; margin-right: 10px; display: inline-block;') do
                mailer_link_to(listing_url(info.listing), style: 'border: none;') do
                  mailer_image_tag(info.photo.version_url(:small), alt: info.listing.title,
                                   style: style_attribute(listing_styles))
                end
              end
            end
            safe_join(out2, "\n")
          end
        end
      end
      safe_join(out, "\n")
    end
  end

  # @option options [Symbol] :icon the name of the icon to include next to the button text
  # @option options [Hash] :button_styles CSS rules to include in the +style+ attribute of the button link
  # @option options [Hash] :icon_styles CSS rules to include in the +style+ attribute of the icon image
  def mailer_action_button(text, url, options = {})
    button_styles = options.fetch(:button_styles, {}).reverse_merge(
      :'font-size'         => '18px',
      :'line-height'       => '20px',
      :'font-weight'       => '500',
      :'background-image'  => "url('#{image_path('icons/emails/button_bg.png')}')",
      :'background-repeat' => 'repeat-x',
      :'background-color'  => '#799DD3',
      :'font-family'       => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
      :color               => '#FFFFFF',
      :'letter-spacing'    => '1px',
      :'text-align'        => 'center',
      :padding             => '8px 8px 8px 8px',
      :'min-width'         => '210px',
      :height              => '24px',
      :display             => 'inline-block',
      :'vertical-align'    => 'top',
      :'text-decoration'   => 'none'
    )
    mailer_link_to(url, class: 'action-button', width: 210, height: 24, style: style_attribute(button_styles)) do
      out = []
      if options[:icon].present?
        icon = options[:icon].to_s.capitalize
        icon_styles = options.fetch(:icon_styles, {}).reverse_merge(
          :display         => 'inline-block',
          :'border-style'  => 'none',
          :width           => '22px',
          :height          => '20px',
          :'margin-right'  => '5px',
          :'margin-top'    => '1px'
        )
        out << mailer_image_tag("icons/emails/#{icon}ButtonIcon.png", class: 'action-button-icon',
                                style: style_attribute(icon_styles))
      end
      if text.present?
        button_text_styles = options.fetch(:button_text_styles, {}).reverse_merge(
          :'font-family'       => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
          :'font-size'         => '18px',
          :'line-height'       => '20px',
          :'font-weight'       => '500',
          :color               => '#FFFFFF',
          :'letter-spacing'    => '1px',
          :'text-align'        => 'center',
          :display             => 'inline-block',
          :'vertical-align'    => 'top',
          :'text-decoration'   => 'none'
        )
        out << content_tag(:span, text, style: style_attribute(button_text_styles))
      end
      safe_join(out, "\n")
    end
  end

  # @option options [Hash] :container_styles CSS rules to include in the +style+ attribute of the containing element
  # @option options [Hash] :name_styles CSS rules to include in the +style+ attribute of the user name element
  # @option options [Hash] :comment_styles CSS rules to include in the +style+ attribute of the comment element
  def mailer_user_comment(commenter, comment, options = {})
    container_styles = options.fetch(:container_styles, {}).reverse_merge(
      :display      => 'block',
      :'text-align' => 'left',
      :padding      => '0px 25px 0px 25px'
    )
    content_tag(:div, class: 'actioner-info-container', style: style_attribute(container_styles)) do
      out = []
      name_styles = options.fetch(:name_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '16px',
        :'line-height'   => '20px',
        :'font-weight'   => '600',
        :color           => '#1D1D1B',
        :display         => 'block',
        :'margin-bottom' => '10px'
      )
      out << content_tag(:span, commenter.name, class: 'actioner-name', style: style_attribute(name_styles))
      comment_styles = options.fetch(:comment_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '14px',
        :'line-height'   => '18px',
        :'font-weight'   => '300',
        :color           => '#1D1D1B',
        :display         => 'inline-block',
        :width           => '430px',
        :'margin-bottom' => '20px'
      )
      out << content_tag(:span, mailer_sanitize_comment(comment.text, tags: []), style: style_attribute(comment_styles))
      safe_join(out, "\n")
    end
  end

  # @option options [Hash] :container_styles CSS rules to include in the +style+ attribute of the containing element
  # @option options [Hash] :name_styles CSS rules to include in the +style+ attribute of the user name element
  # @option options [Hash] :comment_styles CSS rules to include in the +style+ attribute of the comment element
  def mailer_user_comment_and_reply(commenter, comment, replier, reply, options = {})
    container_styles = options.fetch(:container_styles, {}).reverse_merge(
      :display      => 'block',
      :'text-align' => 'left',
      :padding      => '0px 25px 0px 25px'
    )
    content_tag(:div, class: 'actioner-info-container', style: style_attribute(container_styles)) do
      out = []
      comment_styles = options.fetch(:comment_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '14px',
        :'line-height'   => '18px',
        :'font-weight'   => '300',
        :color           => '#6F6F6E',
        :display         => 'inline-block',
        :width           => '430px',
        :'margin-bottom' => '16px',
        :'border-left-width' => '3px',
        :'border-left-style' => 'solid',
        :'border-left-color' => '#799DD3',
        :'padding-left'  => '16px'
      )
      out << content_tag(:span, mailer_sanitize_comment(comment.text, tags: []),
        class: 'comment-text', style: style_attribute(comment_styles))
      name_styles = options.fetch(:name_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '16px',
        :'line-height'   => '20px',
        :'font-weight'   => '600',
        :color           => '#1D1D1B',
        :display         => 'block',
        :'margin-bottom' => '10px'
      )
      out << content_tag(:span, replier.name, class: 'actioner-name', style: style_attribute(name_styles))
      reply_styles = options.fetch(:reply_styles, {}).reverse_merge(
        :'font-family'   => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'font-size'     => '14px',
        :'line-height'   => '18px',
        :'font-weight'   => '300',
        :color           => '#1D1D1B',
        :display         => 'inline-block',
        :width           => '430px',
        :'margin-bottom' => '16px'
      )
      out << content_tag(:span, mailer_sanitize_comment(reply.text, tags: []),
        class: 'body-text', style: style_attribute(reply_styles))
      safe_join(out, "\n")
    end
  end

  def mailer_user_follow_action(recipient, user)
    content_tag(:div, class: 'action-area') do
      content_tag(:div, class: 'action-button-container') do
        if recipient.following?(user)
          mailer_action_button(t('shared_mailer.action.follow.button.view_profile', user: user.firstname),
                               public_profile_url(user))
        else
          mailer_action_button(t('shared_mailer.action.follow.button.follow'), public_profile_url(user), icon: :follow,
                               styles: 'float: none !important;')
        end
      end
    end
  end

  def mailer_user_reply_to_action(recipient, commenter, listing)
    content_tag(:div, class: 'action-area', style: 'padding: 0px 25px 0px 25px') do
      out = []
      text_styles = {
        :'font-size'   => '12px',
        :'font-family' => "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif",
        :'line-height' => '18px',
        :'font-weight' => '300',
        :color         => '#9F9F9E',
        :display       => 'inline-block',
        :'text-align'  => 'center',
        :margin        => '9px 0px 16px 0px',
        :float         => 'left'
      }
      out << content_tag(:div, class: 'body-text', style: style_attribute(text_styles)) do
        t('shared_mailer.action.reply.text')
      end
      out << content_tag(:div, class: 'action-button-container', style: 'float: right;') do
        button_styles = {
          :'margin-bottom' => '25px',
          :float           => 'right'
        }
        mailer_action_button(t('shared_mailer.action.reply.button', commenter: commenter.firstname),
                             listing_url(listing), icon: :comment, styles: button_styles)
      end
      safe_join(out, "\n")
    end
  end
end
