class CancelledOrderMailer < MailerBase
  helper :application, :date, :listings, :order, :carrier

  def created_for_seller(order)
    @order = order
    @user = order.listing.seller
    setup_mail(:created_for_seller, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def created_for_buyer(order)
    @order = order
    @user = order.buyer
    setup_mail(:created_for_buyer, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end
end
