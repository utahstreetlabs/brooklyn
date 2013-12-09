require 'ladon'

class SendCreditReminderOne < Ladon::Job
  @queue = :email

  def self.work(credit_id)
    with_error_handling("send credit reminder 1", credit_id: credit_id) do
      credit = Credit.find(credit_id)
      CreditMailer.credit_reminder_1(credit).deliver unless credit.used?
    end
  end
end
