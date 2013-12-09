xml.instruct!

xml.orders do
  @orders.each do |order|
    xml << render(partial: 'summary', locals: { order: order, listing: order.listing })
  end
end
