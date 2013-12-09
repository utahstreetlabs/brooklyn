class ListingOfferMailer < MailerBase

  def created_for_admin(offer)
    @offer = offer
    setup_mail(:created_for_admin, headers: {to: Brooklyn::Application.config.email.to.offer},
               params: {listing: @offer.listing.title})
  end
end
