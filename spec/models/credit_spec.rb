require 'spec_helper'
require 'timecop'

describe Credit do
  let(:expires_at) { nil }
  let(:amount) { 100 }
  subject { Factory.create(:credit, expires_at: expires_at, amount: amount) }

  it 'is invalid without an amount' do
    subject.amount = nil
    subject.save.should be_false
  end

  it 'is invalid without a numeric amount' do
    subject.amount = 'forty bucks!'
    subject.save.should be_false
  end

  it 'is invalid with a negative amount' do
    subject.amount = 0
    subject.save.should be_false
  end

  describe '#expired?' do
    it 'should be true if expired_at is in the past' do
      subject.expires_at = Time.now - 30
      subject.expired?.should be_true
    end
    it 'should be false if expired_at is nil' do
      subject.expires_at = nil
      subject.expired?.should be_false
    end
    it 'should be false if expired_at is in the future' do
      subject.expires_at = Time.now + 30
      subject.expired?.should be_false
    end
  end

  context "creation" do
    subject{Factory.build(:credit)}
    it "increases the associated user's credit balance" do
      subject.user.credit_balance.should == 0
      subject.save!
      subject.user.credit_balance.should == subject.amount
    end
  end

  describe "expiration" do
    let!(:user) { subject.user }
    let(:expires_at) { Time.now + 1000 }
    it "should debit the user's credit balance" do
      subject.user.credit_balance.should == subject.amount
      Timecop.travel(Time.now + 1500) do
        subject.user.credit_balance.should == 0
      end
    end

    it "should not debit the user's account too much" do
      credit = FactoryGirl.create(:credit, user: user, amount: 100)
      subject.user.credit_balance.should == (subject.amount + credit.amount)
      Timecop.travel(Time.now + 1500) do
        subject.user.credit_balance.should == 100
      end
    end
  end

  context "scopes" do
    let(:user) { Factory.create(:registered_user) }
    let!(:expired_unused) { Factory.create(:credit, user: user, expires_at: Time.now - 30)}
    let!(:unexpired) { Factory.create(:credit, user: user, amount: 5.0, expires_at: Time.now + 30)}
    let!(:never_expires) { Factory.create(:credit, user: user, expires_at: nil)}

    describe "#unused" do
      context "with a pending order" do
        let(:price) { 100.0 }
        let(:listing) { Factory.create(:active_listing, price: price) }
        let!(:order) { Factory.create(:pending_order, listing: listing, buyer: user) }
        before do
          listing.reload
          order.apply_credit_amount!(unexpired.amount)
        end

        context "and no listing specified" do
          it "should not return the 'used' credit" do
            Credit.unused(user).should have(2).items
            unexpired.amount_used.should == unexpired.amount
            unexpired.amount_remaining.should == 0.0
          end
        end

        context "and the listing specified" do
          it "should include the 'used' credit" do
            Credit.unused(user, listing: listing).should have(3).items
            unexpired.amount_used(listing: listing).should == 0.0
            unexpired.amount_remaining(listing: listing).should == unexpired.amount
          end
        end
      end
    end

    describe "#unused.expired" do
      it "should select only expired, unused credits" do
        Credit.expired.unused(user).should == [expired_unused]
      end
    end

    describe "#unexpired" do
      it "should select only unexpired credits" do
        Credit.unexpired.should == [unexpired, never_expires]
      end
    end

    describe "#available_by_expiration_time" do
      let(:listing) { FactoryGirl.create(:active_listing, price: 40.0) }
      let(:offer) { Factory.create(:offer) }
      let(:seller_offer) { Factory.create(:offer, sellers: [listing.seller]) }
      let(:min_purchase_offer) { Factory.create(:offer, minimum_purchase: 40.0) }
      let!(:unexpired_later) { Factory.create(:credit, user: user, expires_at: Time.now + 100)}
      let!(:unexpired_in_the_middle_offer) do
        Factory.create(:credit, user: user, expires_at: Time.now + 50, offer: offer)
      end
      let!(:unexpired_in_the_middle) { Factory.create(:credit, user: user, expires_at: Time.now + 50)}
      let!(:unexpired_in_the_middle_seller_offer) do
        Factory.create(:credit, user: user, expires_at: Time.now + 50, offer: seller_offer)
      end
      let!(:unexpired_in_the_middle_minimum_purchase) do
        Factory.create(:credit, user: user, expires_at: Time.now + 50, offer: min_purchase_offer)
      end
      it "should select only unexpired, unused credits and order by expiration date" do
        Credit.available_by_expiration_time(user, listing: listing).should == [
          unexpired_in_the_middle_seller_offer,
          unexpired_in_the_middle_minimum_purchase,
          unexpired_in_the_middle_offer,
          unexpired,
          unexpired_in_the_middle,
          unexpired_later,
          never_expires
        ]
      end
    end
  end

  context "offer-specific credits" do
    let(:user) { Factory.create(:registered_user) }
    let(:offer_seller) { Factory.create(:registered_user) }
    let(:offer_listing) { Factory.create(:active_listing, seller_id: offer_seller.id) }
    let(:offerless_listing) { Factory.create(:active_listing) }
    let(:offer) do
      offer = Factory.create(:offer)
      offer.seller_ids = [offer_seller.id]
      offer
    end
    let!(:offer_credit) { Factory.create(:credit, amount: 1.0, user: user, expires_at: nil, offer_id: offer.id)}
    let!(:offerless_credit) { Factory.create(:credit, amount: 2.0, user: user, expires_at: nil)}

    before do
      Offer.stubs(:all).returns([offer])
    end

    describe "#unused" do
      context "without specifying listing" do
        it "should return all credits with unused value" do
          Credit.unused(user).should == [offer_credit, offerless_credit]
        end
      end

      context "with listing that has an associated offer" do
        it "should include the credit for associated offer" do
          Credit.unused(user, listing: offer_listing).should == [offer_credit, offerless_credit]
        end
      end

      context "with listing that has no associated offer" do
        it "should not include the credit tied to offers from other sellers" do
          Credit.unused(user, listing: offerless_listing).should == [offerless_credit]
        end
      end

    end
  end

  describe "#grant!" do
    let(:user) { Factory.create(:registered_user) }
    let(:attrs) { {foo: :bar} }

    context "when the user is being granted an invitee credit" do
      before { user.stubs(:accepted_invite?).returns(true) }

      it "should create a credit and credit the user's accepted invite" do
        user.expects(:credit_invite_acceptance!)
        credit = Credit.grant!(user, :invitee, attrs)
        user.credit_balance.should == credit.amount
      end
    end

    context "when the user is not being granted an invitee credit" do
      before { Lagunitas::CreditTrigger.expects(:create).with('Inviter', user.id, is_a(Integer), attrs) }

      it "should create a credit and credit the user's accepted invite" do
        credit = Credit.grant!(user, :inviter, attrs)
        user.credit_balance.should == credit.amount
      end
    end
  end

  describe "#eligibility" do
    let(:user) { stub_user('Fred Armisen') }

    it 'fails when user is not connected or registered' do
      user.stubs(:connected?).returns(false)
      user.stubs(:registered?).returns(false)
      expect { Credit.eligibility(user, :whatever) }.to raise_exception(Credit::InvalidUserState)
    end

    context "for invitee credit" do
      let(:type) { :invitee }
      let(:invite) { stub 'invite' }
      let(:inviter) { stub_user 'Carrie Brownstein' }

      it 'fails when user has not accepted an invite' do
        user.stubs(:accepted_invite?).returns(nil)
        expect { Credit.eligibility(user, type) }.to raise_exception(Credit::InviteNotFound)
      end

      context 'when user has accepted an invite' do
        before do
          user.stubs(:accepted_invite?).returns(true)
          user.stubs(:accepted_inviter).returns(inviter)
        end

        it 'fails when inviter is not registered' do
          inviter.stubs(:registered?).returns(false)
          expect { Credit.eligibility(user, type) }.to raise_exception(Credit::InviterNotRegistered)
        end

        it 'fails when inviter is capped' do
          inviter.stubs(:credited_invite_acceptance_capped?).returns(true)
          user.expects(:add_top_message).with(is_a(InviteeInviteCappedTopMessage))
          expect { Credit.eligibility(user, type) }.to raise_exception(Credit::InviteCapped)
        end

        it 'fails when user is not minimally connected' do
          inviter.stubs(:credited_invite_acceptance_capped?).returns(false)
          user.person.stubs(:minimally_connected?).returns(false)
          user.expects(:add_top_message).with(is_a(TopMessage))
          expect { Credit.eligibility(user, type) }.to raise_exception(Credit::InvalidUserConnectivity)
        end

        it 'succeeds otherwise' do
          inviter.stubs(:credited_invite_acceptance_capped?).returns(false)
          user.person.stubs(:minimally_connected?).returns(true)
          Credit.eligibility(user, type).should be_true
        end
      end
    end

    context "for inviter credit" do
      let(:type) { :inviter }
      let(:invitee) { stub_user 'Elisabeth Moss' }
      let(:options) { {invitee_id: invitee.id} }
      before { User.stubs(:find_by_id).with(invitee.id).returns(invitee) }

      it 'fails when inviter is capped' do
        user.stubs(:credited_invite_acceptance_capped?).returns(true)
        expect { Credit.eligibility(user, type, options) }.to raise_exception(Credit::InviteCapped)
      end

      it 'fails when invitee is not minimally connected' do
        user.stubs(:credited_invite_acceptance_capped?).returns(false)
        invitee.person.stubs(:minimally_connected?).returns(false)
        expect { Credit.eligibility(user, type, options) }.to raise_exception(Credit::InvalidUserConnectivity)
      end

      it 'succeeds otherwise' do
        user.stubs(:credited_invite_acceptance_capped?).returns(false)
        invitee.person.stubs(:minimally_connected?).returns(true)
        Credit.eligibility(user, type, options).should be_true
      end
    end
  end

  describe "#grant_if_eligible!" do
    let(:user) { stub_user('Neil Young') }
    context "invitee credit" do
      it "should be granted if the user is minimally connected" do
        Credit.expects(:eligibility).returns(:credit_valid)
        Credit.expects(:grant!).with(user, :invitee, {})
        Credit.grant_if_eligible!(user, :invitee)
      end

      it "should not be granted if the user is not minimally connected" do
        Credit.expects(:eligibility).raises(Credit::InvalidUserConnectivity)
        Credit.expects(:grant!).never
        Credit.grant_if_eligible!(user, :invitee)
      end
    end
  end

  describe '#amount_for_accepted_invites' do
    it 'returns the invitee cap when the inviter sends many invites' do
      count = (Credit.max_inviter_credits_per_invitee / Credit.amount_for_accepted_invite) * 2
      Credit.amount_for_accepted_invites(count).should == Credit.max_inviter_credits_per_invitee
    end

    it 'returns less than the invitee cap when the inviter sends a few invites' do
      count = (Credit.max_inviter_credits_per_invitee / Credit.amount_for_accepted_invite) - 1
      Credit.amount_for_accepted_invites(count).should == Credit.amount_for_accepted_invite * count
    end
  end

  describe "#consume!" do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:order) { Factory.create(:pending_order, buyer: user) }
    let(:earlier_expiration) { 20.minutes }
    let(:later_expiration) { 30.minutes }
    before do
      Factory.create(:credit, expires_at: Time.now + later_expiration, amount: 5, user: user)
      Factory.create(:credit, expires_at: Time.now + earlier_expiration, amount: 5, user: user)
      Factory.create(:credit, expires_at: Time.now + later_expiration, amount: 5, user: user)
    end

    it "should use credits closest to expiring first" do
      user.credit_balance.should == 15
      Credit.consume!(5, order)
      Timecop.travel(Time.now + (earlier_expiration + later_expiration) / 2) do
        user.credit_balance.should == 10
      end
    end

    it 'should raise if the buyer does not have enough credit' do
      expect { Credit.consume!(25, order) }.to raise_error(Credit::NotEnoughCreditAvailable)
      user.credit_balance.should == 15
    end
  end

  describe '#assert_buyer_pays_minimum_real_charge!' do
    let(:order) { Factory.create(:pending_order) }

    it 'should raise' do
      expect { Credit.assert_buyer_pays_minimum_real_charge!(order.listing.total_price, order) }.
        to raise_error(Credit::MinimumRealChargeRequired)
    end

    it 'should not raise' do
      expect { Credit.assert_buyer_pays_minimum_real_charge!(order.listing.total_price-1, order) }.
        to_not raise_error(Credit::MinimumRealChargeRequired)
    end
  end

  describe '#inviter_credits_for_user' do
    subject { Credit }

    let(:user) { FactoryGirl.create(:registered_user) }
    let(:invitee1) { stub_user 'Des Kensel' }
    let(:credit1) { FactoryGirl.create(:credit, user: user) }
    let(:trigger1) do
      Lagunitas::InviterCreditTrigger.new(id: 'trigger1', user_id: user.id, credit_id: credit1.id,
        invitee_id: invitee1.id)
    end
    let(:invitee2) { stub_user 'Jeff Matz' }
    let(:credit2) { FactoryGirl.create(:credit, user: user) }
    let(:trigger2) do
      Lagunitas::InviterCreditTrigger.new(id: 'trigger2', user_id: user.id, credit_id: credit2.id,
        invitee_id: invitee2.id)
    end

    before { Lagunitas::CreditTrigger.stubs(:find_for_user).with(user.id).returns([trigger1, trigger2]) }

    it { subject.inviter_credits_for_user(user.id).should include(invitee1.id => credit1, invitee2.id => credit2) }
  end
end
