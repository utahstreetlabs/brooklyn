module SortableHelper
  def sortable(order, title = nil, options = {})
    title ||= order.titleize
    so = sort_order
    sd = sort_direction
    current = so == order.to_s || so.blank? && options[:default] == true
    direction = current && sd == :asc.to_s ? :desc : :asc
    css_class = current ? "current #{direction}" : nil
    link_to title, {:sort => order, :direction => direction}, :class => css_class
  end
end
