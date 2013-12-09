require 'spec_helper'

describe Invites::EmailContext do
  describe '#send_email' do
    it "sends invitation emails to specified addresses" do
      viewer = stub_user('William Adama')
      addresses = ['apollo@galactica.mil', 'starbuck@galactica.mil']
      invite = stub('invite', addresses: addresses, message: "Get in here now!")
      addresses.each do |address|
        Invites::EmailContext.expects(:send_email).with(:invite, viewer, address, invite.message)
        Invites::EmailContext.expects(:track_usage)
      end
      viewer.expects(:mark_inviter!)
      Invites::EmailContext.send_messages(viewer, invite)
    end
  end
end
