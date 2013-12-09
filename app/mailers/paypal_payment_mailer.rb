class PaypalPaymentMailer < MailerBase
  def created(payment)
    @payment = payment
    setup_mail(:created, headers: {to: Brooklyn::Application.config.email.to.paypal_payments},
               params: {order_number: @payment.reference_number})
  end
end
