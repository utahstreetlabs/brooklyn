class InviteeCreditMessage < TopMessage
  include ApplicationHelper
  include ActionView::Helpers::NumberHelper

  def initialize(amount, type, reason=nil)
    params = {
      amount: smart_number_to_currency(amount),
      text: reason
    }
    super(type, params)
  end
end
