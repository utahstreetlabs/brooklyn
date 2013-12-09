class ListingFlagMailer < MailerBase
  include ListingsHelper

  default :to => Brooklyn::Application.config.email.to.info

  def create_notification(flag)
    @flag = flag
    setup_mail(:create_notification)
  end
end
