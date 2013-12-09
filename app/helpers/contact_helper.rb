require 'ostruct'

module ContactHelper
  def sample_invitation(inviter)
    stub_contact = OpenStruct.new(display_name: '__________')
    render(partial: '/contact_mailer/contact_invitation_content', locals: {contact: stub_contact, user: inviter})
  end
end
