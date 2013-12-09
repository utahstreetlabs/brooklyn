require 'spec_helper'

describe Listing do
  subject { InternalListing.new }

  it_should_behave_like "a model with unique slugs", :active_listing
  it { should normalize_attribute(:title).from('Jack Spade   Messenger Bag   ').to('Jack Spade Messenger Bag') }

  describe "#dimension_value_for" do
    before(:each) do
      @category = FactoryGirl.create(:category, :name => 'category')
      @dimension = FactoryGirl.build(:dimension, :name => 'dimension', :category => @category)
      @value = FactoryGirl.build(:dimension_value, :value => 'New with tags', :dimension => @dimension)
      @listing = FactoryGirl.create(:incomplete_listing, :category => @category)
    end

    it "returns a value when one is attached for a dimension" do
      @listing.dimension_values << @value
      @listing.dimension_value_for(@dimension).should_not be_nil
    end

    it "returns no value when one is not attached for a dimension" do
      @listing.dimension_value_for(@dimension).should be_nil
    end
  end

  describe '#assign_attributes' do
    it 'assigns a category when provided a category id' do
      category = FactoryGirl.create(:category)
      subject.assign_attributes(category_id: category.id)
      subject.category.should == category
    end

    it 'assigns a category when provided a category slug' do
      category = FactoryGirl.create(:category)
      subject.assign_attributes(category_slug: category.slug)
      subject.category.should == category
    end

    it 'assigns dimension value ids when provided a dimension hash' do
      dimension = FactoryGirl.create(:dimension)
      dimension_value = FactoryGirl.create(:dimension_value, dimension: dimension)
      subject.assign_attributes(dimensions: {dimension.name => dimension_value.id.to_s})
      subject.dimension_value_ids.should == [dimension_value.id]
    end

    it 'assigns tags when provided a tag string' do
      tags = FactoryGirl.create_list(:tag, 2)
      subject.assign_attributes(tags: tags.map(&:name).join(', '))
      subject.tags.should == tags
    end

    context 'when provided a shipping option code' do
      let(:code) { :medium_box }

      before do
        subject.seller = FactoryGirl.create(:registered_user)
        FactoryGirl.create(:shipping_address, user: subject.seller, default_address: true)
        shipping_option_config = ShippingOption.active_option_config(code)
      end

      context "with default attributes" do
        before { subject.assign_attributes(shipping_option_code: code.to_s) }

        its(:shipping_option) { should be }
        its(:return_address) { should be }
      end

      context "when a return address exists" do
        let(:address) { FactoryGirl.create(:return_address, :name => 'Taken', :line1 => '11 Foo St.') }

        before { subject.assign_attributes(shipping_option_code: code.to_s, return_address: address) }

        its(:return_address) { should_not == address }
      end
    end
  end

  describe "#save" do
    context "a valid listing" do
      subject { FactoryGirl.build(:incomplete_listing) }

      it "sets the listing's foreign key" do
        subject.save
        subject.item_id.should_not be_nil
      end

      it "persists the listing's item" do
        subject.save
        subject.item.persisted?.should be_true
      end
    end

    context "an invalid listing" do
      subject { FactoryGirl.build(:incomplete_listing, :title => nil) }

      it "does not set the listing's foreign key" do
        subject.save
        subject.item_id.should be_nil
      end

      it "does not set the listing's item" do
        subject.save
        subject.item.should be_nil
      end
    end
  end

  it "validates title presence" do
    subject.save
    subject.should have(1).error_on(:title)
  end

  it "validates title length" do
    subject.title = 'x'*266
    subject.save
    subject.should have(1).error_on(:title)
  end

  describe 'title validation' do
    let(:listing) do
      l = FactoryGirl.create(:active_listing)
      l.update_attribute(:title, 'x'*100)
      l
    end

    it "validates too-long listing title when title is dirty" do
      listing.title = 'y'*100
      expect { listing.deactivate! }.to raise_error(StateMachine::InvalidTransition)
      listing.should have(1).error_on(:title)
    end

    it "does not validate too-long listing title when title is not dirty" do
      expect {listing.deactivate!}.to_not raise_error
    end
  end

  describe "#description=" do
    let(:bad_html) { '<p>here is a paragraph</div></p></div>' }
    let(:good_html) { '<p>here is a paragraph</p>' }

    subject { FactoryGirl.build(:incomplete_listing, description: bad_html) }
    its(:description) { should == good_html }
  end

  it "clears out invalid dimension values when changing category" do
    dimension = FactoryGirl.create(:dimension)
    dimension_value = FactoryGirl.create(:dimension_value, dimension: dimension)
    listing = FactoryGirl.create(:active_listing, category: dimension.category, dimension_values: [dimension_value])
    new_dimension = FactoryGirl.create(:dimension)
    new_dimension_value = FactoryGirl.create(:dimension_value, dimension: new_dimension)

    listing.category = new_dimension.category
    listing.dimension_values << new_dimension_value
    listing.save!

    listing.dimension_values.to_a.should_not include(dimension_value)
    listing.dimension_values.to_a.should include(new_dimension_value)
  end

  describe "#state" do
    let(:listing) { FactoryGirl.create(:incomplete_listing) }

    it "can be transitioned to suspended" do
      listing.suspend!
      listing.should be_suspended
    end

    [:activate, :sell, :complete].each do |event|
      it "cannot #{event} without a photo" do
        listing.photos.clear
        listing.send(event).should be_false
        listing.should be_incomplete
      end

      it "cannot #{event} with an inactive seller" do
        listing.seller.deactivate!
        listing.send(event).should be_false
        listing.should be_incomplete
      end
    end

    it "transitions to incomplete state if last photo is deleted" do
      listing = FactoryGirl.create(:active_listing)

      listing.photos.clear
      listing.should be_incomplete
    end
  end

  describe '#activate!' do
    let(:listing) { FactoryGirl.create(:inactive_listing) }

    it 'approves the listing when the seller has full listing access' do
      listing.seller.listing_access = User::ListingAccess::FULL
      listing.activate!
      listing.should be_approved
    end

    it 'disapproves the listing when the seller has no listing access' do
      listing.seller.listing_access = User::ListingAccess::NONE
      listing.activate!
      listing.should be_disapproved
    end

    it 'does nothing when the seller has limited listing access' do
      listing.seller.listing_access = User::ListingAccess::LIMITED
      listing.activate!
      listing.should be_not_yet_approved
    end

    it 'does nothing when the seller has undetermined listing access' do
      listing.seller.listing_access = nil
      listing.activate!
      listing.should be_not_yet_approved
    end

    it 'sets has_been_activated' do
      listing.has_been_activated.should be_false
      listing.activate!
      listing.reload.has_been_activated.should be_true
    end

    it "enqueues a job if this is the user's first activation" do
      Listings::AfterActivationJob.expects(:enqueue).with(listing.id, first_activation: true)
      Users::AfterFirstActivationJob.expects(:enqueue).with(anything)
      listing.activate!
    end

    it "does not enqueue a Users::AfterFirstActivation job if this is not the user's first activation" do
      FactoryGirl.create(:active_listing, seller: listing.seller)
      Listings::AfterActivationJob.expects(:enqueue).with(listing.id, first_activation: true)
      Users::AfterFirstActivationJob.expects(:enqueue).never
      listing.activate!
    end

    it "only passes first_activation: true to the AfterActivationJob once" do
      listing.activate!
      listing.deactivate!
      Listings::AfterActivationJob.expects(:enqueue).with(listing.id, first_activation: nil)
      Users::AfterFirstActivationJob.expects(:enqueue).never
      # don't just reload, fetch from db to clear out accessor values
      Listing.find(listing.id).activate!
    end
  end

  describe "#deactivate!" do
    let(:listing) { FactoryGirl.create(:active_listing) }
    before { listing.deactivate! }
    it "transitions the listing to inactive" do
      listing.should be_inactive
    end
  end

  describe "#complete!" do
    let(:listing) { FactoryGirl.create(:incomplete_listing) }

    it "transitions an incomplete listing to inactive" do
      listing.description = 'a thing'
      listing.price = 25.00
      listing.category = FactoryGirl.create(:category)
      listing.photos << FactoryGirl.create(:listing_photo, :listing => listing)
      listing.complete.should be_true
      listing.should be_inactive
    end
  end

  describe "#uncomplete!" do
    [:active, :inactive].each do |state|
      it "transitions the listing from #{state} to incomplete" do
        listing = FactoryGirl.create("#{state}_listing")
        listing.uncomplete!
        listing.should be_incomplete
      end
    end
  end

  describe "#assign_tag_string" do
    subject { FactoryGirl.create(:incomplete_listing) }

    it "can assign tags from a string" do
      subject.assign_tag_string("Foo, Bar, Baz")
      subject.save

      subject.should have(3).tags
    end

    it "should ignore empty tags" do
      subject.assign_tag_string("Foo, , Baz")
      subject.save

      subject.should have(2).tags
    end

    it "can serialize tags back into a string" do
      subject.tags = Tag.find_or_create_all_by_name(["Foo", "Bar", "Baz"])
      subject.save

      subject.tag_string.should == "Foo, Bar, Baz"
    end
  end

  describe '#assign_tag_string' do
    let!(:public_tag) { FactoryGirl.create(:tag, name: 'public') }
    let!(:internal_tag) { FactoryGirl.create(:tag, internal: true, name: 'secret') }
    subject { FactoryGirl.create(:active_listing) }

    it 'adds public tags' do
      subject.assign_tag_string('public,otherpublic')
      subject.tags.should include(public_tag)
    end

    it 'does not add internal tags by default' do
      subject.assign_tag_string('public,otherpublic,secret')
      subject.tags.should include(public_tag)
      subject.tags.should_not include(internal_tag)
    end

    it 'adds internal tags as admin' do
      subject.assign_tag_string('public,otherpublic,secret', as: :admin)
      subject.tags.should include(public_tag)
      subject.tags.should include(internal_tag)
    end

    it 'removes public or internal tags' do
      subject.assign_tag_string('public,otherpublic,secret', as: :admin)
      subject.assign_tag_string('hams')
      subject.tags.should_not include(public_tag)
      subject.tags.should_not include(internal_tag)
    end
  end

  describe '#remove_tags' do
    let(:attached) { FactoryGirl.create(:tag) }
    let(:detached) { FactoryGirl.create(:tag) }
    subject { FactoryGirl.create(:active_listing) }
    before { subject.tags << attached }

    it 'removes an attached tag' do
      expect(subject).to have_tag(attached)
      subject.remove_tags(attached)
      expect(subject).to_not have_tag(attached)
    end

    it 'ignores a detached tag' do
      expect(subject).to_not have_tag(detached)
      subject.remove_tags(detached)
      expect(subject).to have_tag(attached)
      expect(subject).to_not have_tag(detached)
    end

    matcher :have_tag do |tag|
      match { |l| l.tags.exists?(tag) }
    end
  end

  describe '#visible_ids_for_tag_id' do
    let!(:tag) { FactoryGirl.create(:tag) }
    let(:inactive_listing) { FactoryGirl.create(:inactive_listing) }
    let(:sold_listing) { FactoryGirl.create(:sold_listing) }
    let(:active_listing) { FactoryGirl.create(:active_listing) }
    before { tag.listings = [inactive_listing, sold_listing, active_listing] }

    subject { Listing.visible_ids_for_tag_id(tag.id, 9) }
    its(:count) { should == 2 }
    its(:first) { should == active_listing.id }
    its(:last) { should == sold_listing.id }
  end

  context "#initiate_order" do
    let(:buyer) { FactoryGirl.create(:registered_user) }

    context "when listing is not active" do
      subject { FactoryGirl.create(:incomplete_listing) }

      it "should not work" do
        expect { subject.initiate_order(buyer) }.to raise_exception
      end
    end

    context "when listing is active" do
      subject { FactoryGirl.create(:active_listing) }
      let(:buyer) { FactoryGirl.create(:registered_user) }
      before { buyer.stubs(:private?).with(:purchase_details).returns(true) }

      context "and has an order" do
        before { subject.initiate_order(buyer) }

        it "should not work" do
          subject.initiate_order(buyer).should_not be_persisted
        end
      end

      context "and has no order" do
        before { subject.initiate_order(buyer) }

        it "should set the buyer" do
          subject.buyer(true).should eq(buyer)
        end

        it "should set the order" do
          subject.order.should_not be_nil
        end
      end
    end
  end

  it "sells a listing" do
    order = FactoryGirl.create(:pending_order)
    ListingObserver.instance.expects(:after_sell).with(order.listing, instance_of(StateMachine::Transition))
    order.listing.sell!
    order.listing.sold?.should be_true
  end

  context "#can_suspend?" do
    it "is true when the listing is incomplete" do
      FactoryGirl.create(:incomplete_listing).can_suspend?.should be_true
    end

    it "is true when the listing is active" do
      FactoryGirl.create(:active_listing).can_suspend?.should be_true
    end

    it "is false when the listing is sold" do
      FactoryGirl.create(:sold_listing).can_suspend?.should be_false
    end

    it "is false when the listing is cancelled" do
      FactoryGirl.create(:cancelled_listing).can_suspend?.should be_false
    end
  end

  context "#suspend" do
    context "when incomplete" do
      let(:subject) { FactoryGirl.create(:incomplete_listing) }

      before do
        ListingObserver.instance.expects(:after_suspend).with(subject, instance_of(StateMachine::Transition))
      end
    end

    context "when active" do
      let(:subject) { FactoryGirl.create(:active_listing) }

      before do
        ListingObserver.instance.expects(:after_suspend).with(subject, instance_of(StateMachine::Transition))
      end
    end
  end

  describe "#can_cancel?" do
    it "is true if the listing is incomplete" do
      FactoryGirl.create(:incomplete_listing).can_cancel?.should be_true
    end

    it "is true if the listing is active" do
      FactoryGirl.create(:active_listing).can_cancel?.should be_true
    end

    it "is true if the listing is suspended" do
      FactoryGirl.create(:suspended_listing).can_cancel?.should be_true
    end

    it "is false if the listing is sold" do
      FactoryGirl.create(:sold_listing).can_cancel?.should be_false
    end
  end

  context "#cancel" do
    before do
      subject.cancel!
      subject.reload
    end
    context "when incomplete" do
      let(:subject) { FactoryGirl.create(:incomplete_listing) }

      before do
        ListingObserver.instance.expects(:after_cancel).with(subject, instance_of(StateMachine::Transition))
      end
    end

    context "when active" do
      let(:subject) { FactoryGirl.create(:active_listing) }

      before do
        ListingObserver.instance.expects(:after_cancel).with(subject, instance_of(StateMachine::Transition))
      end
    end

    context "with a pending order" do
      let(:subject) { FactoryGirl.create(:pending_order).listing }

      it "should nil out the order" do
        subject.order.should be_nil
      end

      it "should nil out the buyer id" do
        subject.buyer_id.should be_nil
      end
    end
  end

  describe "#relist" do
    subject { FactoryGirl.create(:sold_listing) }

    it "should remove the buyer" do
      subject.relist!
      subject.buyer.should be_nil
    end

    it "should be active" do
      subject.relist!
      subject.active?.should be_true
    end
  end

  context "#can_reactivate?" do
    it "is true when the listing is suspended" do
      FactoryGirl.create(:suspended_listing).can_reactivate?.should be_true
    end

    it "is false when the listing is cancelled" do
      FactoryGirl.create(:cancelled_listing).can_suspend?.should be_false
    end
  end

  context "#new?" do
    let(:listing) { FactoryGirl.create(:active_listing) }

    it "is true when listing less than 24 hours old" do
      Timecop.freeze(Time.now.utc) do
        listing.stubs(:created_at).returns(Time.now.utc - 6.hour)
        listing.new?.should be_true
      end
    end

    it "is false when listing older than 24 hours" do
      Timecop.freeze(Time.now.utc) do
        listing.stubs(:created_at).returns(Time.now.utc - 2.day)
        listing.new?.should be_false
      end
    end
  end

  context "incomplete listings" do
    let(:listing) { FactoryGirl.create(:incomplete_listing, description: nil, price: nil, shipping: nil, tax: nil) }

    it "can be created without any details" do
      listing.persisted?.should be_true
    end

    it "won't transition to active without filling in missing fields" do
      listing.activate.should be_false
    end

    it "will transition to cancelled without filling in missing fields" do
      listing.cancel.should be_true
    end

    # active well tested in other places
    [:suspend, :cancel].each do |state|
      it "will transition via #{state} after filling in missing fields" do
        listing.attributes = {description: 'ham', price: 4, shipping: 1, tax: 1}
        listing.send(state).should be_true
      end
    end
  end

  describe "#incr_views" do
    before { subject.stubs(:anchor_instance).returns(stub('anchor-listing')) }

    it "increments view counts" do
      subject.anchor_instance.expects(:incr_views)
      subject.incr_views
    end
  end

  describe "#incr_shares" do
    let(:sharer) { stub_user('Fred Savage') }
    let(:network) { :twitter }

    before { subject.stubs(:anchor_instance).returns(stub('anchor-listing')) }

    it "increments share counts and fires callback when sharer is provided" do
      subject.anchor_instance.expects(:incr_shares).with(network)
      ListingObserver.instance.expects(:after_share).with(subject, sharer, network)
      subject.incr_shares(sharer, network)
    end

    it "increments share counts but skips callback when sharer is not provided" do
      subject.anchor_instance.expects(:incr_shares).with(network)
      ListingObserver.instance.expects(:after_share).never
      subject.incr_shares(nil, network)
    end
  end

  it "returns share counts" do
    subject.stubs(:anchor_instance).returns(stub(shares: {'twitter' => 5, 'facebook' => 10, 'tumblr' => 3}))
    subject.shares(:twitter).should == 5
    subject.shares.should == 18
  end

  it "returns more listings from this listing's seller" do
    listing = FactoryGirl.create(:active_listing)
    listing2 = FactoryGirl.create(:active_listing, seller: listing.seller)
    listing3 = FactoryGirl.create(:cancelled_listing, seller: listing.seller)
    rv = listing.more_from_this_seller
    rv.should have(1).listing
    rv.first.should == listing2
  end

  context "#cancellable" do
    let!(:active) { FactoryGirl.create(:active_listing) }
    let!(:sold) { FactoryGirl.create(:sold_listing) }
    let!(:incomplete) { FactoryGirl.create(:incomplete_listing) }
    let!(:cancelled) { FactoryGirl.create(:cancelled_listing) }
    subject { Listing.cancellable }
    its(:count) { should == 2 }
    it "doesn't include the sold listing" do
      subject.each { |l| l.should_not == sold }
    end
    it "doesn't include the cancelled listing" do
      subject.each { |l| l.should_not == cancelled }
    end
  end

  context 'featured in its category' do
    let(:shotguns) { FactoryGirl.create(:category, name: 'Shotguns') }
    let(:listing) { FactoryGirl.create(:incomplete_listing, category: shotguns) }

    describe '#featured_for_category?' do
      it 'returns true when the listing has a category feature' do
        listing.features.create!(featurable: shotguns)
        listing.reload
        listing.featured_for_category?.should be_true
      end

      it 'returns false when the listing does not have a category feature' do
        listing.featured_for_category?.should be_false
      end
    end

    describe '#unfeature_for_category' do
      it 'deletes the category feature' do
        listing.features.create!(featurable: shotguns)
        listing.reload
        listing.unfeature_for_category
        listing.reload
        listing.features.should be_empty
        listing.category_feature.should be_nil
      end
    end

    describe "#update_category_feature" do
      it "does nothing when a category is not specified" do
        listing.features.create!(featurable: shotguns)
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.category_feature.featurable.should == shotguns
      end

      it "stops featuring a category" do
        listing.features.create!(featurable: shotguns)
        listing.reload
        listing.featured_category_toggle = '0'
        listing.save!
        listing.reload
        listing.features.should be_empty
        listing.category_feature.should be_nil
      end

      it "starts featuring a category" do
        listing.featured_category_toggle = '1'
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.category_feature.featurable.should == shotguns
      end
    end
  end


  context 'featured in a tag' do
    let(:ponies) { FactoryGirl.create(:tag, name: 'Ponies') }
    let(:listing) { FactoryGirl.create(:incomplete_listing) }
    before { listing.tags << ponies }

    describe '#featured_for_tag?' do
      it 'returns true when the listing has a tag feature' do
        listing.features.create!(featurable: ponies)
        listing.reload
        listing.featured_for_tag?(ponies).should be_true
      end

      it 'returns false when the listing does not have a tag feature' do
        listing.featured_for_tag?(ponies).should be_false
      end
    end

    describe '#tag_feature' do
      it 'returns an existing tag feature' do
        listing.features.create!(featurable: ponies)
        listing.reload
        listing.tag_feature(ponies).should be
      end

      it 'returns nil for a nonexistent tag feature' do
        listing.tag_feature(ponies).should_not be
      end
    end

    describe "#update_tag_features" do
      it "does nothing when tag ids are not specified" do
        listing.features.create!(featurable: ponies)
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.tag_features.should have(1).feature
        listing.tag_features.first.featurable.should == ponies
      end

      it "stops featuring a tag" do
        listing.features.create!(featurable: ponies)
        listing.reload
        listing.featured_tag_ids = []
        listing.save!
        listing.reload
        listing.features.should be_empty
        listing.tag_features.should be_empty
      end

      it "starts featuring a tag" do
        listing.featured_tag_ids = [ponies.id.to_s]
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.tag_features.should have(1).feature
        listing.tag_features.first.featurable.should == ponies
      end
    end
  end

  context 'featured in its feature list' do
    let(:masters) { FactoryGirl.create(:feature_list, name: 'Masters of the Universe') }
    let(:listing) { FactoryGirl.create(:incomplete_listing) }

    describe '#on_feature_list?' do
      it 'returns true when the listing has a feature list feature' do
        listing.features.create!(featurable: masters)
        listing.reload
        listing.on_feature_list?(masters).should be_true
      end

      it 'returns false when the listing does not have the feature list feature' do
        listing.on_feature_list?(masters).should be_false
      end
    end

    describe '#unfeature_from_feature_list' do
      it 'deletes the feature list feature' do
        listing.features.create!(featurable: masters)
        listing.reload
        listing.unfeature_from_feature_list(masters)
        listing.reload
        listing.features.should be_empty
        listing.feature_list_features.should be_empty
      end
    end

    describe '#feature_list_feature' do
      it 'returns an existing feature list feature' do
        listing.features.create!(featurable: masters)
        listing.reload
        listing.feature_list_feature(masters).should be
      end

      it 'returns nil for a nonexistent feature list feature' do
        listing.feature_list_feature(masters).should_not be
      end
    end

    describe "#update_feature_list_features" do
      it "updates a listing's feature lists" do
        listing.features.create!(featurable: masters)
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.feature_list_features.should have(1).feature
        listing.feature_list_features.first.featurable.should == masters
      end

      it "stops featuring a feature list" do
        listing.features.create!(featurable: masters)
        listing.reload
        listing.featured_feature_list_ids = []
        listing.save!
        listing.reload
        listing.features.should be_empty
        listing.feature_list_features.should be_empty
      end

      it "starts featuring a feature list" do
        listing.featured_feature_list_ids = [masters.id.to_s]
        listing.save!
        listing.reload
        listing.features.should have(1).feature
        listing.feature_list_features.should have(1).feature
        listing.feature_list_features.first.featurable.should == masters
      end
    end
  end

  describe "#set_featured_at" do
    let!(:shotguns) { FactoryGirl.create(:category, name: 'Shotguns') }
    let!(:listing) { FactoryGirl.create(:incomplete_listing) }

    it "sets the attribute when featured for the first time" do
      listing.features.create!(featurable: shotguns)
      Timecop.freeze do
        expect { listing.save! }.to change { listing.featured_at }.from(nil).to(Time.now)
      end
    end

    it "does not set the attribute when it has already been set" do
      listing.features.create!(featurable: shotguns)
      listing.featured_at = Time.now
      expect { listing.save! }.not_to change { listing.featured_at }
    end

    it "does not set the attribute when there are no features" do
      expect { listing.save! }.not_to change { listing.featured_at }
    end
  end

  describe "#api_hash" do
    let(:listing) { FactoryGirl.create(:active_listing) }

    context "full data" do
      subject { listing.api_hash(stub_everything) }

      its([:title]) { should == listing.title }
      its([:description]) { should == listing.description }
      its([:slug]) { should == listing.slug }
      its([:price]) { should == listing.price.to_f }
      its([:shipping]) { should == listing.shipping.to_f }
      its([:created_at]) { should_not be }
      its([:updated_at]) { should_not be }
    end

    context "summary data" do
      subject { listing.api_hash(summary: true) }

      its([:title]) { should_not be }
      its([:description]) { should_not be }
    end
  end

  describe '#related' do
    it 'should gracefully handle solr errors' do
      subject.expects(:more_like_this).raises('connection refused')
      subject.related.should == []
    end
  end

  describe '#sell' do
    describe "race conditions" do
      let!(:listing){ FactoryGirl.create(:active_listing) }
      let!(:other_copy){ Listing.find(listing.id) }

      it "doesn't double sell even in event of race condition" do
        ListingObserver.any_instance.expects(:after_sell).once
        listing.sell
        listing.should be_sold
        other_copy.sell
      end

      it "doesn't reload the second listing if sell hits a race condition" do
        listing.sell
        listing.should be_sold
        other_copy.sell
        other_copy.should_not be_sold
        other_copy.reload.should be_sold
      end
    end
  end

  describe '#size_name=' do
    context 'when tag exists' do
      context 'when tag is a primary tag' do
        let(:size) { FactoryGirl.create(:size_tag) }

        it 'sets size' do
          subject.size_name = size.name
          subject.size.should == size
        end

        it 'removes size' do
          subject.size = size
          subject.size_name = ''
          subject.size.should be_nil
        end
      end

      context 'when tag is a subtag' do
        let(:size) { FactoryGirl.create(:size_subtag) }

        it 'sets size' do
          subject.size_name = size.name
          subject.size.should == size.primary
        end
      end
    end

    context 'when tag does not exist' do
      it 'sets size after creating tag' do
        name = 'Wicked Lahge'
        subject.size_name = name
        subject.size.should be_nil
      end
    end
  end

  describe '#brand_name=' do
    context 'when tag exists' do
      let(:brand) { FactoryGirl.create(:brand_tag) }

      it 'sets brand' do
        subject.brand_name = brand.name
        subject.brand.should == brand
      end

      it 'removes brand' do
        subject.brand = brand
        subject.brand_name = ''
        subject.brand.should be_nil
      end
    end

    context 'when tag does not exist' do
      it 'sets brand after creating tag' do
        name = 'Some Cunthammer'
        Tag.find_by_name(name).should be_nil
        subject.brand_name = name
        subject.brand.should be_a(Tag)
        subject.brand.name.should == name
      end
    end
  end

  describe 'pricing' do
    subject { FactoryGirl.build(:inactive_listing, price: 10.to_d) }

    context 'basic shipping' do
      context 'free' do
        before { subject.shipping = 0.to_d }

        context 'seller pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = true }

          its(:subtotal) { should == 10.to_d }
          its(:buyer_fee) { should == 0.to_d }
          its(:seller_fee) { should == 0.95.to_d }
        end

        context 'buyer pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = false }

          its(:subtotal) { should == 10.to_d }
          its(:buyer_fee) { should == 0.60.to_d }
          its(:seller_fee) { should == 0.35.to_d }
        end
      end

      context 'non-free' do
        before { subject.shipping = 1.to_d }

        context 'seller pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = true }

          its(:subtotal) { should == 11.to_d }
          its(:buyer_fee) { should == 0.to_d }
          its(:seller_fee) { should == 1.05.to_d }
        end

        context 'buyer pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = false }

          its(:subtotal) { should == 11.to_d }
          its(:buyer_fee) { should == 0.66.to_d }
          its(:seller_fee) { should == 0.39.to_d }
        end
      end
    end

    context 'prepaid shipping' do
      before do
        so = subject.build_shipping_option
        so.copy_from_config!(:medium_box)
      end

      context 'free' do
        before { subject.shipping = 0.to_d }

        context 'seller pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = true }

          its(:subtotal) { should == 10.to_d }
          its(:buyer_fee) { should == 0.to_d }
          its(:seller_fee) { should == 12.30.to_d }
        end

        context 'buyer pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = false }

          its(:subtotal) { should == 10.to_d }
          its(:buyer_fee) { should == 0.60.to_d }
          its(:seller_fee) { should == 11.70.to_d }
        end
      end

      context 'non-free' do
        before { subject.shipping = 1.to_d }

        context 'seller pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = true }

          its(:subtotal) { should == 11.00.to_d }
          its(:buyer_fee) { should == 0.to_d }
          its(:seller_fee) { should == 12.40.to_d }
        end

        context 'buyer pays marketplace fee' do
          before { subject.seller_pays_marketplace_fee = false }

          its(:subtotal) { should == 11.00.to_d }
          its(:buyer_fee) { should == 0.66.to_d }
          its(:seller_fee) { should == 11.74.to_d }
        end
      end
    end
  end

  describe '.has_offer_from?' do
    it 'returns true when the user has made an offer' do
      offer = FactoryGirl.create(:listing_offer)
      expect(offer.listing.has_offer_from?(offer.user)).to be_true
    end

    it 'returns false when the user has not made an offer' do
      listing = FactoryGirl.create(:active_listing)
      user = FactoryGirl.create(:registered_user)
      expect(listing.has_offer_from?(user)).to be_false
    end
  end

  describe '#find_recently_created' do
    it 'returns a recently created listing' do
      listing = FactoryGirl.create(:active_listing)
      expect(Listing.find_recently_created).to eq([listing])
    end

    it 'excludes listings' do
      listing = FactoryGirl.create(:active_listing)
      expect(Listing.find_recently_created(excluded_ids: listing.id)).to be_empty
    end

    it 'excludes non-visible listings' do
      listing = FactoryGirl.create(:cancelled_listing)
      expect(Listing.find_recently_created).to be_empty
    end
  end

  describe '::find_trending' do
    context "when there are liked listings within the window" do
      let!(:listings) { FactoryGirl.create_list(:active_listing, 2) }
      before { stub_like_results(1, listings.second.id, total_count: 5) }

      it 'returns the trending listings' do
        (relation, paginator) = Listing.find_trending(1, page: 1, per: 1)
        expect(relation).to eq([listings.second])
        expect(paginator.current_page).to eq(1)
        expect(paginator.total_count).to eq(5)
      end
    end

    context "where there are no liked listings within the window" do
      let!(:listings) { FactoryGirl.create_list(:active_listing, 2) }
      before { stub_like_results(1, nil) }

      it 'returns recent listings instead' do
        (relation, paginator) = Listing.find_trending(1, page: 1, per: 1)
        expect(relation).to eq([listings.second])
        expect(paginator.current_page).to eq(1)
        expect(paginator.total_count).to eq(2)
      end
    end

    def stub_like_results(page, ids, options = {})
      ids = Array.wrap(ids).compact
      ids.stubs(:current_page).returns(page)
      ids.stubs(:total_count).returns(options.fetch(:total_count, ids.size))
      Listing.stubs(:recently_liked).with(is_a(Integer), has_entries(page: page)).returns(ids)
    end
  end

  describe '::find_trending_ids' do
    let!(:listings) { FactoryGirl.create_list(:active_listing, 2) }
    before { Listing.stubs(:recently_liked).returns([]) }

    it 'returns the trending listing ids' do
      ids = Listing.find_trending_ids(1)
      expect(ids).to eq([listings.second.id, listings.first.id])
    end

    it 'excludes of ids from a seller' do
      ids = Listing.find_trending_ids(1, exclude_sellers: listings.first.seller)
      expect(ids).to eq([listings.second.id])
    end
  end
end
