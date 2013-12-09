class CreditNotification < Notification
  attr_accessor :credit, :offer

  def complete?
    ! (credit.nil? || offer.nil?)
  end
end
