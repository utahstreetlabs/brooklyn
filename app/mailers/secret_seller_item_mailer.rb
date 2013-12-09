class SecretSellerItemMailer < MailerBase
  def submitted(id)
    @item = SecretSellerItem.find(id)
    attachments.inline[@item.photo_identifier] = @item.photo.read if @item.photo
    setup_mail(:submitted, headers: {to: Brooklyn::Application.config.email.to.secret_seller})
  end
end
