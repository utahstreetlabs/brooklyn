require "spec_helper"

describe Users::AutofollowJob do
  subject { Users::AutofollowJob }

  let(:user) { stub_user('Constantin Stanislavski') }
  let(:autofollow_list) { [stub_user('Lee Strasberg'), stub_user('Sanford Meisner')] }

  it "follows the autofollow users" do
    User.expects(:find).with(user.id).returns(user)
    User.expects(:autofollow_list).returns(autofollow_list)
    autofollow_list.each do |c|
      user.expects(:follow!).
        with(c, has_entries(attrs: {suppress_followee_notifications: true, suppress_fb_follow: true},
                            follow_type: AutomaticFollow))
    end
    subject.perform(user.id)
  end
end
