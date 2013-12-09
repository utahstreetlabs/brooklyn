class CreditMailer < MailerBase
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  helper :application

  def credit_reminder_1(credit)
    @credit = credit
    @user = credit.user
    @days_remaining = pluralize((credit.time_remaining/1.day).ceil, 'day')
    @credit_amount = number_to_currency(credit.amount_remaining)
    campaign = 'creditreminder1'
    category = 'creditreminder'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    params = {
      days_remaining: @days_remaining,
      credit_amount: @credit_amount
    }
    setup_mail(:credit_reminder_1, headers: {to: @user.email}, params: params)
  end

  def credit_reminder_2(credit)
    @credit = credit
    @user = credit.user
    @hours_remaining = pluralize((credit.time_remaining/1.hour).ceil, 'hour')
    @credit_amount = number_to_currency(credit.amount_remaining)
    campaign = 'creditreminder2'
    category = 'creditreminder'
    google_analytics source: 'notifications', campaign: campaign
    sendgrid_category category
    params = {
      hours_remaining: @hours_remaining,
      credit_amount: @credit_amount
    }
    setup_mail(:credit_reminder_2, headers: {to: @user.email}, params: params)
  end
end
