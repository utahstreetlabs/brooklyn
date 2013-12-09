require 'spec_helper'

describe OrderMailer do
  context "for a confirmed order" do
    let(:listing) { FactoryGirl.create(:active_listing, price: 100.00, pricing_version: 2) }
    let(:order) { FactoryGirl.create(:confirmed_order, listing: listing) }

    it "builds a purchased message for the seller" do
      expect { OrderMailer.purchased_for_seller(order) }.to_not raise_error
    end

    context "builds a purchased message for the buyer" do
      subject { OrderMailer.purchased_for_buyer(order) }

      context "with buyer fees" do
        its(:to_s) { should have_content('$106.00') }
      end
    end

    it "builds a purchased and unshipped reminder for the seller" do
      expect { OrderMailer.purchased_unshipped_reminder_for_seller(order) }.to_not raise_error
    end
  end

  context "for a shipped order" do
    subject{ FactoryGirl.create(:shipped_order) }

    it "builds a shipped message for the seller" do
      lambda { OrderMailer.shipped_for_seller(subject) }.should_not raise_error
    end

    it "builds a shipped message for the buyer" do
      lambda { OrderMailer.shipped_for_buyer(subject) }.should_not raise_error
    end

    context "whose delivery confirmation period elapsed" do
      it "builds a message for the seller" do
        Timecop.travel(subject.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
          lambda { OrderMailer.delivery_confirmation_period_elapsed_for_seller(subject) }.should_not raise_error
        end
      end

      it "builds a message for the buyer" do
        Timecop.travel(subject.shipped_at + Order.delivery_confirmation_period_duration + 1.day) do
          lambda { OrderMailer.delivery_confirmation_period_elapsed_for_buyer(subject) }.should_not raise_error
        end
      end
    end

    context "reported as not delivered" do
      it "builds a message for the help staff" do
        lambda { OrderMailer.not_delivered_for_help(subject) }.should_not raise_error
      end
    end

    context "for which delivery confirmation was requested but not received" do
      before do
        requested_at =  Time.zone.now - Order.delivery_non_confirmation_followup_period_duration - 1.day
        subject.update_column(:delivery_confirmation_requested_at, requested_at)
      end

      it "builds a message for help" do
        expect { OrderMailer.delivery_not_confirmed_for_help(subject) }.to_not raise_error
      end
    end
  end

  context "for a delivered order" do
    subject{ FactoryGirl.create(:delivered_order) }

    it "builds a delivered message for the seller" do
      lambda { OrderMailer.delivered_for_seller(subject) }.should_not raise_error
    end

    it "builds a delivered message for the buyer" do
      lambda { OrderMailer.delivered_for_buyer(subject) }.should_not raise_error
    end
  end

  context "for a complete order" do
    let!(:seller) { FactoryGirl.create(:registered_user) }
    let!(:default_deposit_account) { FactoryGirl.create(:paypal_account, user: seller, default: true) }
    let!(:listing) { FactoryGirl.create(:active_listing, seller: seller) }
    subject { FactoryGirl.create(:complete_order, listing: listing) }

    it "builds a completed message for the seller" do
      lambda { OrderMailer.completed_for_seller(subject) }.should_not raise_error
    end

    it "builds a completed message for the buyer" do
      lambda { OrderMailer.completed_for_buyer(subject) }.should_not raise_error
    end
  end
end
