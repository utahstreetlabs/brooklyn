require 'spec_helper'

describe Users::AfterFirstActivationJob do
  subject { Users::AfterFirstActivationJob }

  let(:user) { stub_user 'Johnny Halliday' }

  describe "#perform" do
    it 'should track the first activation in mixpanel' do
      User.expects(:find).returns(user)
      user.expects(:mixpanel_set!).with(has_key(:first_listed_at))
      subject.perform(user.id)
    end
  end
end
