class ShipmentMailer < MailerBase
  helper :date, :listings, :carrier

  def tracking_number_updated_for_buyer(shipment)
    @shipment = shipment
    @user = shipment.order.buyer
    campaign = 'trackingnumberupdate'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:tracking_number_updated_for_buyer, :headers => {:to => @user.email})
  end

  def tracking_number_updated_for_seller(shipment)
    @shipment = shipment
    @user = shipment.order.listing.seller
    campaign = 'trackingnumberupdate'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:tracking_number_updated_for_seller, :headers => {:to => @user.email})
  end
end
