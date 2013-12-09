# Models a payment from the Copious marketplace bank account to a PayPal deposit account.
#
# Because Balanced does not support paying to PayPal accounts, we must pay them manually.
class PaypalPayment < SellerPayment
  default_sort_column :created_at
  default_sort_direction :desc
  sort_columns 'deposit_accounts.email', 'amount', 'users.name', 'orders.reference_number', 'orders.settled_at',
               'paid_at', 'state'
  paginates_per 100

  after_commit on: :create do
    PaypalPayments::AfterCreationJob.enqueue(self.id)
  end

  delegate :reference_number, :settled_at, to: :order

  def recipient
    deposit_account.user
  end

  def recipient_name
    recipient.name
  end

  def paypal_email
    deposit_account.email
  end

  class << self
    alias :super_datagrid :datagrid
  end

  def self.datagrid(params = {})
    relation = includes([:order, {deposit_account: :user}])
    # pending comes after paid in natural sort order, so reverse the sort
    relation = relation.order("#{quoted_table_name}.state DESC") unless params[:sort] == 'state'
    relation.super_datagrid(params)
  end

  def self.pay_all!(ids = [])
    ids = Array.wrap(ids).compact
    return false unless ids.any?
    transaction do
      where(id: ids).each { |p| p.pay! if p.can_pay? }
      true
    end
  end
end
