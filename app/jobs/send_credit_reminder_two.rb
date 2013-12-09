require 'ladon'

class SendCreditReminderTwo < Ladon::Job
  @queue = :email

  def self.work(credit_id)
    with_error_handling("send credit reminder 2", credit_id: credit_id) do
      credit = Credit.find(credit_id)
      CreditMailer.credit_reminder_2(credit).deliver unless credit.used?
    end
  end
end
