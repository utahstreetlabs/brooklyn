module ScrollHelper
  def infinite_scroll_widgets
    out = content_tag(:div, id: 'loading-container', style: 'display: none;') do
      content_tag(:div, class: 'loading-container listing-collection') do
        content_tag(:div, class: 'spinner-loading') do
          out2 = []
          out2 << content_tag(:div, '', class: 'circleG circleG_1')
          out2 << content_tag(:div, '', class: 'circleG circleG_2')
          out2 << content_tag(:div, '', class: 'circleG circleG_3')
          safe_join(out2)
        end
      end
    end
    out + content_tag(:div, class: 'scroll-to-top-container') do
      link_to('Scroll to Top', nilhref, id: 'scroll-top', style: 'display: none;', class: 'button')
    end
  end
end
