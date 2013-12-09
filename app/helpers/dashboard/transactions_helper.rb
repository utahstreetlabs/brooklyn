module Dashboard
  module TransactionsHelper
    def dashboard_tx_account(tx, viewer)
      if tx.account
        if tx.card_account?
          card_type = t(".tbody.credit_card.#{tx.account.card_type.downcase}")
          t('.tbody.funding_source.card', card_type: card_type, last_four: tx.account.last_four)
        elsif tx.bank_account?
          if tx.credited_to_paypal?
            if tx.deposit_account
              t('.tbody.funding_source.paypal', email: tx.deposit_account.email)
            else
              t('.tbody.funding_source.paypal_unknown')
            end
          else
            t('.tbody.funding_source.bank_account', name: tx.account.name, last_four: tx.account.last_four)
          end
        else
          logger.warn("Unknown Balanced funding source type #{tx.account.class}")
          t('.tbody.funding_source.unknown')
        end
      else
        t('.tbody.account.unknown')
      end
    end

    def dashboard_tx_type(tx)
      out = [t(".tbody.type.#{tx.type}")]
      state = if tx.credited_to_paypal? && tx.paypal_payment
        t(".tbody.credit_state.#{tx.paypal_payment.state}")
      elsif tx.credit?
        t(".tbody.credit_state.#{tx.state}")
      end
      if state
        out << ' -'
        out << tag(:br)
        out << state
      end
      safe_join(out)
    end
  end
end
