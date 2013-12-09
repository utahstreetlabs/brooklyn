require 'spec_helper'

describe Users::AfterOnboardingJob do
  subject { Users::AfterOnboardingJob }

  let(:user) { stub_user 'Johnny Halliday' }
  before { User.stubs(:find).with(user.id).returns(user) }
  let(:autofollowings) { [stub('follow1'), stub('follow2')] }
  let(:interest_followings) { [stub('follow3'), stub('follow4')] }

  describe "#work" do
    it 'rebuilds the feed and shares autofollows' do
      user.expects(:autofollowings).returns(autofollowings)
      user.expects(:interest_followings).returns(interest_followings)
      (interest_followings + autofollowings).each { |f| f.expects(:post_to_facebook!) }

      subject.work(user.id)
    end
  end
end
