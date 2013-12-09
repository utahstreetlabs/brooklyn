require 'contacts/invite'

class EmailAccounts::ContactsController < ApplicationController
  respond_to :json
  before_filter { @account = EmailAccount.find(params[:email_account_id]) }

  def index
    contacts = @account.unregistered_contacts
    render_jsend(success: {
      contacts: contacts.map { |c| { id: c.id, name: c.display_name, email: c.email } }.sort_by { |c| c[:name] },
      status: @account.sync_state
    })
  end
end
