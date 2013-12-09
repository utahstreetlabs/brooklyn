class OrderMailer < MailerBase
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  helper :application, :date, :listings, :order, :carrier

  def purchased_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'purchasedseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:purchased_for_seller, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def purchased_for_buyer(order)
    @order = order
    @user = order.buyer
    campaign = 'purchasedbuyer'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:purchased_for_buyer, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def shipped_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'shippedseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:shipped_for_seller, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def shipped_for_buyer(order)
    @order = order
    @user = order.buyer
    campaign = 'shippedbuyer'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:shipped_for_buyer, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def purchased_unshipped_reminder_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'unshippedreminderseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:purchased_unshipped_reminder_for_seller, :headers => {:to => @user.email},
      :params => {:title => order.listing.title, :buyer_name => order.buyer.name})
  end

  def delivery_confirmation_period_elapsed_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'deliveryconfirmationelapsedseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:delivery_confirmation_period_elapsed_for_seller, headers: {to: @user.email},
               params: {title: order.listing.title})
  end

  def delivery_confirmation_period_elapsed_for_buyer(order)
    @order = order
    @user = order.buyer
    campaign = 'deliveryconfirmationelapsedbuyer'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:delivery_confirmation_period_elapsed_for_buyer, headers: {to: @user.email},
               params: {title: order.listing.title})
  end

  def delivered_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'deliveredforseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:delivered_for_seller, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def delivered_for_buyer(order)
    @order = order
    @user = order.buyer
    campaign = 'deliveredforbuyer'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:delivered_for_buyer, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def completed_for_seller(order)
    @order = order
    @user = order.listing.seller
    campaign = 'completedforseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:completed_for_seller, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def completed_for_buyer(order)
    @order = order
    @user = order.buyer
    campaign = 'completedforbuyer'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:completed_for_buyer, :headers => {:to => @user.email}, :params => {:title => order.listing.title})
  end

  def not_delivered_for_help(order)
    @order = order
    setup_mail(:not_delivered_for_help, headers: {to: Brooklyn::Application.config.email.to.help},
               params: {reference_number: order.reference_number})
  end

  def delivery_not_confirmed_for_help(order)
    @order = order
    setup_mail(:delivery_not_confirmed_for_help, headers: {to: Brooklyn::Application.config.email.to.help},
               params: {reference_number: order.reference_number})
  end
end
