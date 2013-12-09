class BankPaymentMailer < MailerBase
  def paid_for_seller(payment)
    @payment = payment
    @user = payment.order.listing.seller
    campaign = 'sellerpaymentclearedforseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:paid_for_seller, headers: {to: @user.email}, params: {title: payment.order.listing.title})
  end

  def rejected_for_seller(payment)
    @payment = payment
    @user = payment.order.listing.seller
    campaign = 'sellerpaymentrejectedforseller'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category campaign
    setup_mail(:rejected_for_seller, headers: {to: @user.email}, params: {title: payment.order.listing.title})
  end
end
