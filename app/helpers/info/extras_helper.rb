module Info
  module ExtrasHelper
    def external_bookmarklet_button
      content_tag(:div, id: 'copious-bookmarklet', data: {role: 'get-bookmarklet'}) do
        href = <<JS
javascript:void((function(d){
var e=d.createElement('script');e.setAttribute('type','text/javascript');
e.setAttribute('charset','UTF-8');e.setAttribute('src',
'#{Brooklyn::Application.config.bookmarklet.host || Rails.application.routes.url_helpers.root_url}
/assets/bookmarklet.js?r='+Math.random()*99999999);d.body.appendChild(e)})(document));
JS
        # Stripping crlfs here because IE doesn't like them
        href = href.gsub(/[\r\n]/, "")
        bootstrap_button(t("info.extras.bookmarklet.button.title"), href,
          onclick: "alert('Drag me to the bookmarks bar'); return false;", id: 'copious-bookmarklet-button')
      end
    end

    # Different platforms have different command sequences for showing the bookmarks bar.
    def browser_bookmarks_bar_instructions
      user_agent = UserAgent.parse(request.user_agent)
      platform = user_agent.platform
      browser = user_agent.browser
      return unless (platform && browser)
      sequence = t("info.extras.bookmarks.command_sequence.#{browser.downcase}.#{platform.downcase}", default: "")
      return unless sequence.present?
      out = []
      out << t("info.extras.bookmarks.cantsee")
      out << sequence
      safe_join(out, ' ')
    end
  end
end
