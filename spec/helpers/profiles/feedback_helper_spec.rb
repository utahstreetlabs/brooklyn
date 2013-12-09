require 'spec_helper'

describe Profiles::FeedbackHelper do
  describe '#feedback_partner' do
    let(:viewer) { stub_user '' }
    let(:buyer) { stub_user 'Joey Ramone' }
    let(:positive_feedback) do
      stub('positive-feedback', rated_positive?: true, rated_negative?: false, visible_to?: true, buyer: buyer)
    end
    let(:negative_feedback) do
      stub('negative-feedback', rated_positive?: false, rated_negative?: true, visible_to?: true, buyer: buyer)
    end

    context "on selling page" do
      let(:type) { :selling }

      context "with negative feedback" do
        let(:feedback) { negative_feedback }

        it "shows buyer name to the seller" do
          feedback.stubs(:sold_by?).with(viewer).returns(true)
          feedback.stubs(:bought_by?).with(viewer).returns(false)
          helper.feedback_partner(feedback, viewer, type).should be
        end

        it "shows buyer name to the buyer" do
          feedback.stubs(:sold_by?).with(viewer).returns(false)
          feedback.stubs(:bought_by?).with(viewer).returns(true)
          helper.feedback_partner(feedback, viewer, type).should be
        end

        it "does not show buyer name to anybody else" do
          feedback.stubs(:sold_by?).with(viewer).returns(false)
          feedback.stubs(:bought_by?).with(viewer).returns(false)
          helper.feedback_partner(feedback, viewer, type).should_not be
        end
      end

      context "with positive feedback" do
        let(:feedback) { positive_feedback }

        it "shows buyer name to the seller" do
          feedback.stubs(:sold_by?).with(viewer).returns(true)
          feedback.stubs(:bought_by?).with(viewer).returns(false)
          helper.feedback_partner(feedback, viewer, type).should be
        end

        it "shows buyer name to the buyer" do
          feedback.stubs(:sold_by?).with(viewer).returns(false)
          feedback.stubs(:bought_by?).with(viewer).returns(true)
          helper.feedback_partner(feedback, viewer, type).should be
        end

        it "shows buyer name to anybody else" do
          feedback.stubs(:sold_by?).with(viewer).returns(false)
          feedback.stubs(:bought_by?).with(viewer).returns(false)
          helper.feedback_partner(feedback, viewer, type).should be
        end
      end
    end
  end
end
