module Admin
  module PaymentsIntegrationHelpers
    shared_context "viewing pending paypal payment" do
      before do
        @order = given_order(:settled, deposit_account: {type: :paypal_account})
        login_as('starbuck@galactica.mil', admin: true)
        visit admin_payments_paypal_index_path
      end

      def payment_should_be_pending
        @order.paypal_payment.should be_pending
      end

      def mark_payment_paid
        check "id_#{@order.paypal_payment.id}"
        find("input[type=submit]").click
      end

      def payment_should_be_paid
        current_path.should == admin_payments_paypal_index_path
        page.should have_flash_message(:notice, 'admin.payments.paypal.paid_all')
        @order.reload
        @order.paypal_payment.should be_paid
      end
    end
  end
end
