class OfferSessionObserver < ActiveModel::Observer
  observe :session

  def after_sign_in(session)
    if session.user && session.user.registered? && session[:offer_id]
      if offer = Offer.find_by_uuid(session[:offer_id])
        offer.earn(session.user)
      end
      session.delete(:offer_id)
    end
  end
end
