require 'ladon'

class GrantCredit < Ladon::Job
  @queue = :credits

  def self.work(user_id, type, attrs = {})
    with_error_handling("Granting credit", user_id: user_id, type: type, attrs: attrs) do
      Credit.grant_if_eligible!(User.find(user_id), type, attrs)
    end
  end
end
