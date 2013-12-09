class ContactMailer < MailerBase
  helper :application

  # Returns a mail message to invite someone to the platform (from an address book import)
  def contact_invitation(contact)
    @contact = contact
    @user = contact.email_account.user
    setup_mail(:contact_invitation, :headers => {:to => @contact.email}, :params => {:name => @user.name})
  end
end
