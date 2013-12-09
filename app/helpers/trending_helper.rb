module TrendingHelper
  def trending_header(options = {})
    content_tag(:div, class: 'feed-header-container trending') do
      content_tag(:div, class: 'feed-header') do
        out = []
        out << content_tag(:h1, t('shared.welcome_headers.trending.logged_in.title'))
        out << content_tag(:p, t('shared.welcome_headers.trending.logged_in.description_html'))
        safe_join(out)
      end
    end
  end
end
