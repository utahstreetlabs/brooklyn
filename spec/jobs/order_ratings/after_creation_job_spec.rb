require 'spec_helper'

describe OrderRatings::AfterCreationJob do
  subject { OrderRatings::AfterCreationJob }
  let(:rating) { mock('rating') }

  describe '#inject_feedback_notification' do
    context 'when the rating is positive' do
      before do
        rating.stubs(:positive?).returns(true)
        rating.stubs(:negative?).returns(false)
      end

      it 'injects a feedback increased job' do
        subject.expects(:inject_feedback_increased_notification).with(rating)
        subject.inject_feedback_notification(rating)
      end
    end

    context 'when the rating is negative' do
      before do
        rating.stubs(:positive?).returns(false)
        rating.stubs(:negative?).returns(true)
      end

      it 'injects a feedback decreased job' do
        subject.expects(:inject_feedback_decreased_notification).with(rating)
        subject.inject_feedback_notification(rating)
      end
    end
  end
end
