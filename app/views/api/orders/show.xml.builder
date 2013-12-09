xml.instruct!

xml << render(partial: 'summary', locals: { order: @order, listing: @order.listing })
