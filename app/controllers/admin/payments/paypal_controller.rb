class Admin::Payments::PaypalController < ApplicationController
  layout 'admin'
  set_flash_scope 'admin.payments.paypal'

  def index
    authorize!(:read, PaypalPayment)
    @payments = PaypalPayment.datagrid(params)
  end

  def pay_all
    authorize!(:pay, PaypalPayment)
    if PaypalPayment.pay_all!(params[:id])
      set_flash_message(:notice, :paid_all)
    else
      set_flash_message(:alert, :pay_none_selected)
    end
    redirect_to(admin_payments_paypal_index_path)
  end
end
