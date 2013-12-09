require 'spec_helper'

describe Offer do
  [:name, :descriptor, :ab_tag, :destination_url, :info_url, :landing_page_headline, :fb_story_name, :fb_story_caption,
   :fb_story_description].each do |attribute|
    context attribute do
      it { should normalize_attribute(attribute).from(nil).to(nil) }
      it { should normalize_attribute(attribute).from('').to(nil) }
      it { should normalize_attribute(attribute).from('   ').to(nil) }
      it { should normalize_attribute(attribute).from(' foo  bar ').to('foo bar') }
    end
  end

  context 'landing_page_text' do
    it { should normalize_attribute(:landing_page_text).from(nil).to(nil) }
    it { should normalize_attribute(:landing_page_text).from('').to(nil) }
    it { should normalize_attribute(:landing_page_text).from('   ').to(nil) }
    # interior whitespace is preserved
    it { should normalize_attribute(:landing_page_text).from(' foo  bar ').to('foo  bar') }
  end

  [:amount, :minimum_purchase].each do |attribute|
    context attribute do
      it { should normalize_attribute(attribute).from(nil).to(nil) }
      it { should normalize_attribute(attribute).from('').to(nil) }
      it { should normalize_attribute(attribute).from('   ').to(nil) }
      it { should normalize_attribute(attribute).from('$45.95').to(45.95) }
    end
  end

  [:available, :duration].each do |attribute|
    context attribute do
      it { should normalize_attribute(attribute).from(nil).to(nil) }
      it { should normalize_attribute(attribute).from('').to(nil) }
      it { should normalize_attribute(attribute).from('   ').to(nil) }
      it { should normalize_attribute(attribute).from('14.41').to(14) }
      it { should normalize_attribute(attribute).from('1000').to(1000) }
    end
  end

  [:new_users, :existing_users, :signup].each do |attribute|
    context attribute do
      it { should normalize_attribute(attribute).from("1").to(true) }
      it { should normalize_attribute(attribute).from("0").to(false) }
    end
  end

  # string presence
  [:name, :descriptor].each do |attribute|
    context attribute do
      it "fails validation with blank value" do
        Offer.new(attribute => nil).should have(1).error_on(attribute)
      end

      it "passes validation with present value" do
        Offer.new(attribute => 'foo').should have(:no).errors_on(attribute)
      end
    end
  end

  # number presence
  [:available, :amount, :duration].each do |attribute|
    context attribute do
      it "fails validation with blank value" do
        Offer.new(attribute => nil).should have(1).error_on(attribute)
      end

      it "passes validation with present value" do
        Offer.new(attribute => 1).should have(:no).errors_on(attribute)
      end
    end
  end

  # text
  [:name, :descriptor, :ab_tag, :landing_page_headline, :fb_story_name, :fb_story_caption].each do |attribute|
    context attribute do
      it 'fails validation with too long value' do
        Offer.new(attribute => 'f'*300).should have(1).error_on(attribute)
      end

      it 'passes validation with appropriately long value' do
        Offer.new(attribute => 'f').should have(:no).errors_on(attribute)
      end
    end
  end

  # urls
  [:destination_url, :info_url].each do |attribute|
    context attribute do
      it 'fails validation with too long, invalid value' do
        Offer.new(attribute => 'f'*300).should have(2).errors_on(attribute)
      end

      it 'fails validation with appropriately long, invalid value' do
        Offer.new(attribute => 'f').should have(1).error_on(attribute)
      end

      it 'passes validation with appropriately long, valid value' do
        Offer.new(attribute => 'http://example.com/').should have(:no).errors_on(attribute)
      end
    end
  end

  # positive integers
  [:available, :duration].each do |attribute|
    context attribute do
      it 'fails validation with non-integer value' do
        Offer.new(attribute => 'asdf').should have(1).error_on(attribute)
      end

      it 'fails validation with negative value' do
        Offer.new(attribute => -5).should have(1).error_on(attribute)
      end

      it 'fails validation with zero value' do
        Offer.new(attribute => 0).should have(1).error_on(attribute)
      end

      it 'passes validation with positive value' do
        Offer.new(attribute => 5).should have(:no).errors_on(attribute)
      end
    end
  end

  # future dates
  [:expires_at].each do |attribute|
    context attribute do
      it 'fails validation with past date' do
        Offer.new(attribute => (Date.current-1).to_s).should have(1).error_on(attribute)
      end

      it 'fails validation with current date' do
        Offer.new(attribute => Date.current.to_s).should have(1).error_on(attribute)
      end

      it 'passes validation with future date' do
        Offer.new(attribute => (Date.current+1).to_s).should have(:no).errors_on(attribute)
      end
    end
  end

  context 'amount' do
    it 'fails validation with negative value' do
      Offer.new(amount: -5.55).should have(1).error_on(:amount)
    end

    it 'fails validation with zero value' do
      Offer.new(amount: 0).should have(1).error_on(:amount)
    end

    it 'passes validation with positive value' do
      Offer.new(amount: 5.55).should have(:no).errors_on(:amount)
    end
  end

  context 'minimum_purchase' do
    it 'fails validation with negative value' do
      Offer.new(minimum_purchase: -5.55).should have(1).error_on(:minimum_purchase)
    end

    it 'passes validation with zero value' do
      Offer.new(minimum_purchase: 0).should have(:no).errors_on(:minimum_purchase)
    end

    it 'passes validation with positive value' do
      Offer.new(minimum_purchase: 5.55).should have(:no).errors_on(:minimum_purchase)
    end
  end

  context 'duration' do
    it 'fails validation with value greater than maximum' do
      Offer.new(duration: 100000).should have(1).error_on(:duration)
    end

    it 'passes validation with value less than maximum' do
      Offer.new(duration: 1000).should have(:no).errors_on(:duration)
    end
  end

  context 'eligibility' do
    it 'fails validation when no option is selected' do
      Offer.new.should have(1).error_on(:eligibility)
    end

    it 'passes validation when new users is selected' do
      Offer.new(new_users: '1').should have(:no).errors_on(:eligibility)
    end

    it 'passes validation when existing users is selected' do
      Offer.new(existing_users: '1').should have(:no).errors_on(:eligibility)
    end
  end

  context 'uuid' do
    it 'generates a uuid and passes validation with blank value' do
      o = Offer.new
      o.should have(:no).errors_on(:uuid)
      o.uuid.should be
    end

    it 'fails validation with too long, invalid value' do
      Offer.new(uuid: '@'*300).should have(2).errors_on(:uuid)
    end

    it 'fails validation with appropriately long, invalid value' do
      Offer.new(uuid: '@').should have(1).error_on(:uuid)
    end

    it 'fails validation with duplicate value' do
      existing = FactoryGirl.create(:offer)
      Offer.new(uuid: existing.uuid).should have(1).error_on(:uuid)
    end

    it 'passes validation with appropriately long, valid value' do
      Offer.new(uuid: 'instyle').should have(:no).errors_on(:uuid)
    end
  end

  context 'fb_story_image' do
    it "fails validation when the image isn't present" do
      Offer.new(fb_story_image: nil).should have(1).error_on(:fb_story_image)
    end

    it 'fails validation when dimensions are too small' do
      File.open(fixture_file('Bonsai.gif')) do |f|
        Offer.new(fb_story_image: f).should have(1).error_on(:fb_story_image)
      end
    end

    it 'fails validation when aspect ratio is too big' do
      File.open(fixture_file('PP_Panoram.jpg')) do |f|
        Offer.new(fb_story_image: f).should have(1).error_on(:fb_story_image)
      end
    end

    it 'passes validation when image is appropriately sized' do
      File.open(fixture_file('hamburgler.jpg')) do |f|
        Offer.new(fb_story_image: f).should have(:no).errors_on(:fb_story_image)
      end
    end
  end

  context '.seller_slugs=' do
    subject { create_offer }
    let!(:seller_offers) { FactoryGirl.create_list(:seller_offer, 2, offer: subject) }
    let!(:new_seller) { FactoryGirl.create(:seller) }

    it 'adds and deletes seller offers based on seller slugs' do
      subject.seller_slugs = "#{new_seller.slug}, #{seller_offers.first.seller.slug}"
      subject.seller_offers.map { |o| o.seller.slug }.sort.should ==
        [new_seller.slug, seller_offers.first.seller.slug].sort
    end

    it 'deletes existing seller offers' do
      subject.seller_slugs = nil
      subject.seller_offers.should be_empty
    end
  end

  context '.tag_slugs=' do
    subject { create_offer }
    let!(:tag_offers) { FactoryGirl.create_list(:tag_offer, 2, offer: subject) }
    let!(:new_tag) { FactoryGirl.create(:tag) }

    it 'adds and deletes tag offers based on tag slugs' do
      subject.tag_slugs = "#{new_tag.slug}, #{tag_offers.first.tag.slug}"
      subject.tag_offers.map { |o| o.tag.slug }.sort.should == [new_tag.slug, tag_offers.first.tag.slug].sort
    end

    it 'deletes existing tag offers' do
      subject.tag_slugs = nil
      subject.tag_offers.should be_empty
    end
  end

  context "#earn" do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:offer) { create_offer }

    before { Person.any_instance.stubs(:minimally_connected?).returns(true) }

    describe "when offer is available" do
      it "works" do
        Timecop.freeze do
          offer.earn(user)
          earned = user.credits.first
          earned.offer_id.should == offer.id
          earned.amount.should == offer.amount
          earned.expires_at.should == Time.now + offer.duration.minutes
        end
      end
    end

    describe "when the offer cannot be granted" do
      let(:elide_top_message) { false }
      before { user.expects(:add_top_message).with(InviteeCreditMessage.new(0, reason)) }

      context "because the user is existing and the offer requires new users" do
        let(:offer) { create_offer(existing_users: false) }
        let(:reason) { :invalid_new_only }
        let(:elide_top_message) { true }

        it "adds the :invalid_new_only top message" do
          user.stubs(:just_registered?).returns(false)
          offer.earn(user)
        end
      end

      context "because the user is new and the offer requires existing users" do
        let(:offer) { create_offer(new_users: false) }
        let(:reason) { :invalid_existing_only }

        it "adds the :invalid_existing_only top message" do
          offer.earn(user)
        end
      end

      context "because the total count of available offers has already been earned" do
        let(:user2) { FactoryGirl.create(:registered_user) }
        let(:user3) { FactoryGirl.create(:registered_user) }
        let(:reason) { :invalid_total_user_limit }

        it "adds the :invalid_total_user_limit top message" do
          offer.earn(user2)
          offer.earn(user3)
          offer.earn(user)
        end
      end

      context "when a user has earned an offer the maximum number of times already" do
        let(:reason) { :invalid_per_user_limit }

        it "adds the :invalid_per_user_limit top message" do
          user.expects(:add_top_message).with(InviteeCreditMessage.new(offer.amount, :invitee_credited))
          2.times { offer.earn(user) }
        end
      end

      context "when the user is not minimally connected" do
        before { Person.any_instance.expects(:minimally_connected?).returns(false) }
        let(:reason) { :invalid_user_connectivity }

        it "adds the :invalid_user_connectivity top message" do
          offer.earn(user)
        end
      end

      context "when the user has credits" do
        let(:offer) { create_offer(no_credit_users: true) }
        let(:reason) { :invalid_has_credit }
        before { FactoryGirl.create(:credit, user: user)}

        it "adds the :invalid_has_credit top message" do
          offer.earn(user)
        end
      end

      context "when the user has purchased" do
        let(:offer) { create_offer(no_purchase_users: true) }
        let(:reason) { :invalid_has_purchased }
        before { FactoryGirl.create(:pending_order, buyer: user)}

        it "adds the :invalid_has_purchased top message" do
          offer.earn(user)
        end
      end
    end
  end

  context "#earned_by_id" do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:user2) { FactoryGirl.create(:registered_user) }
    let(:offer) { create_offer }
    let(:offer2) { create_offer }

    before do
      Person.any_instance.stubs(:minimally_connected?).returns(true)
      offer.earn(user)
      offer.earn(user2)
      offer2.earn(user)
    end
    it "should return earned count by id in a hash" do
      result = Offer.earned_by_id
      result[offer.id].should == 2
      result[offer2.id].should == 1
      result[:notanoffer].should_not be
    end
  end

  describe "#signup_offer" do
    let!(:not_signup) { create_offer }
    subject { Offer.signup_offer(true) }

    context "with only a non-signup offer" do
      it { should_not be }
    end

    context "with an expired signup offer" do
      let!(:expired_signup) do
        offer = create_offer(signup: true)
        offer.expires_at = 1.day.ago
        offer.save!(validate: false)
        offer
      end
      it { should_not be}
    end

    context "with a signup offer that has been consumed" do
      let!(:consumed_signup) { create_offer(signup: true, expires_at: 1.day.from_now, available: 1) }
      let(:consumer) { FactoryGirl.create(:registered_user) }
      before do
        Person.any_instance.stubs(:minimally_connected?).returns(true)
        consumed_signup.earn(consumer)
      end
      it { should_not be }
    end

    context "with a non-expiring offer" do
      let!(:noexpire_signup) { create_offer(signup: true, expires_at: nil) }
      it { should == noexpire_signup }
    end

    context "with an unexpired offer" do
      let!(:signup) { create_offer(signup: true, expires_at: 1.day.from_now) }
      it { should == signup }
    end
  end

  describe '#valid_for_listing' do
    let(:listing_a_tags) { '' }
    let(:listing_b_tags) { '' }
    let(:offer_tags) { '' }
    let(:offer_sellers) { '' }
    let!(:listing_a) do
      l = FactoryGirl.create(:active_listing)
      l.tag_string = listing_a_tags
      l
    end
    let!(:listing_b) do
      l = FactoryGirl.create(:active_listing)
      l.tag_string = listing_b_tags
      l
    end
    let!(:offer) do
      o = create_offer
      o.tag_slugs = offer_tags
      o.seller_slugs = offer_sellers
      o.save!
      o
    end

    context 'when the offer has no tags or sellers' do
      let(:offer_tags) { '' }
      let(:offer_sellers) { '' }
      it 'should apply to any listing' do
        Offer.valid_for_listing(listing_a).should include(offer)
        Offer.valid_for_listing(listing_b).should include(offer)
      end
    end

    context 'when the offer has sellers but no tags' do
      let(:offer_tags) { '' }
      let(:offer_sellers) { listing_a.seller.slug }
      it 'should apply only to the listings from that seller' do
        Offer.valid_for_listing(listing_a).should include(offer)
        Offer.valid_for_listing(listing_b).should_not include(offer)
      end
    end

    context 'when the offer has tags but no sellers' do
      let(:listing_a_tags) { 'bacon,ham' }
      let(:listing_b_tags) { 'ham' }
      let(:offer_tags) { 'bacon,asphalt' }
      let(:offer_sellers) { '' }
      it 'should apply only to the listings from that seller' do
        Offer.valid_for_listing(listing_a).should include(offer)
        Offer.valid_for_listing(listing_b).should_not include(offer)
      end
    end

    context 'when the offer has tags and sellers' do
      let(:listing_a_tags) { 'bacon,ham' }
      let(:listing_b_tags) { 'ham' }
      let(:offer_tags) { 'bacon,asphalt' }
      let(:offer_sellers) { listing_a.seller.slug }

      it 'should apply to listings that match both and should not apply to listings that match neither' do
        Offer.valid_for_listing(listing_a).should include(offer)
        Offer.valid_for_listing(listing_b).should_not include(offer)
      end

      context 'when listings match only tag or only sellers' do
        let(:offer_sellers) { listing_b.seller.slug }

        it 'should apply to the union of the tag and seller sets' do
          Offer.valid_for_listing(listing_a).should include(offer)
          Offer.valid_for_listing(listing_b).should include(offer)
        end
      end
    end
  end

  def create_offer(options = {})
    FactoryGirl.create(:offer, options)
  end
end
