# -*- coding: utf-8 -*-
require 'spec_helper'
require 'timecop'

describe User do
  # we don't use the "a model with unique slugs" shared example group as slugging happens for User during a state
  # transition, not at creation

  context "a new user" do
    let(:subject) { User.new }

    it "is valid" do
      subject.should be_valid
    end

    it "is a guest" do
      subject.should be_guest
    end
  end

  it { should normalize_attribute(:email).from('blah@test.com  ').to('blah@test.com') }

  context "a guest user" do
    let(:subject) { FactoryGirl.create(:guest_user) }

    it "fails to register with blank first name" do
      subject.firstname = nil
      subject.connect.should be_false
      subject.errors[:firstname].should include(model_error(:firstname, :blank))
    end

    it "fails to register with too long first name" do
      subject.firstname = 'f' * 65
      subject.connect.should be_false
      subject.errors[:firstname].should include(model_error(:firstname, :too_long, count: 64))
    end

    context "when connecting" do
      before do
        subject.email = Factory.next(:email)
        subject.firstname = 'Rilo'
        subject.lastname = 'Kiley'
      end

      it "becomes connected" do
        subject.connected?.should be_false
        subject.connect!
        subject.connected?.should be_true
      end

      it "sets connected_at" do
        subject.connected_at.should be_nil
        subject.connect!
        subject.connected_at.should be
      end

      it "sets name" do
        subject.name.should be_nil
        subject.connect!
        subject.name.should be
      end
    end
  end

  context "a connected user" do
    let(:subject) { FactoryGirl.create(:connected_user) }

    it "fails to register with blank email" do
      subject.email = nil
      subject.register.should be_false
      subject.errors[:email].should include(model_error(:email, :blank))
    end

    it "fails to register with taken email" do
      existing = FactoryGirl.create(:registered_user)
      subject.email = existing.email
      subject.register.should be_false
      subject.errors[:email].should include(model_error(:email, :taken))
    end

    it "fails to register with too long email" do
      subject.email = 'f' * 256
      subject.register.should be_false
      subject.errors[:email].should include(model_error(:email, :too_long, count: 255))
    end

    it "fails to register with invalid email" do
      subject.email = '!@##$^@$&$*%^@@#$$#$'
      subject.register.should be_false
      subject.errors[:email].should include(model_error(:email, :invalid))
    end

    it "fails to register with too long last name" do
      subject.lastname = 'f' * 65
      subject.register.should be_false
      subject.errors[:lastname].should include(model_error(:lastname, :too_long, count: 64))
    end

    it "fails to register with blank password" do
      # password and password_confirmation must be non-nil in order for password checking to kick in
      subject.password = ''
      subject.password_confirmation = ''
      subject.register.should be_false
      subject.errors[:password].should include(model_error(:password, :blank))
    end

    it "fails to register with unconfirmed password" do
      subject.password = 'boo'
      subject.password_confirmation = 'radley'
      subject.register.should be_false
      subject.errors[:password].should include(model_error(:password, :confirmation))
    end

    # blank slug is not possible since the before callback slugifies if necessary (tested later)

    it "fails to register with too long slug" do
      subject.slug = 'f' * 256
      subject.register.should be_false
      subject.errors[:slug].should include(model_error(:slug, :too_long, count: 128))
    end

    it "fails to register with invalid slug" do
      subject.slug = '!@%@%!@!@#'
      subject.register.should be_false
      subject.errors[:slug].should include(model_error(:slug, :invalid))
    end

    context "when registering" do
      before do
        subject.password = 'test'
        subject.password_confirmation = 'test'
      end

      it "becomes registered" do
        subject.registered?.should be_false
        subject.register
        subject.registered?.should be_true
      end

      it "sets registered_at" do
        subject.registered_at.should be_nil
        subject.register!
        subject.registered_at.should be
      end

      it "sets slug" do
        subject.slug.should be_nil
        subject.register!
        subject.slug.should be
      end

      it "sets just_registered?" do
        subject.just_registered?.should be_false
        subject.register!
        subject.just_registered?.should be_true
      end
    end
  end

  context "#follow!" do
    it "has 5 followers after 5 people follow" do
      user = FactoryGirl.create(:registered_user)
      (1..5).each do |i|
        follower = FactoryGirl.create(:registered_user)
        follower.follow!(user)
      end
      user.followers.should have(5).followers
    end

    context "with a follower" do
      let(:follower) { FactoryGirl.create(:registered_user) }
      it "is following 5 people after 5 follows" do
        (1..5).each do |i|
          user = FactoryGirl.create(:registered_user)
          follower.follow!(user)
        end
        follower.followees.should have(5).people
      end

      it "ignores a follow request for a user it is already following" do
        followee = FactoryGirl.create(:registered_user)
        follower.follow!(followee)
        follower.follow!(followee)
      end

      it "ignores a follow request for a blocked user" do
        followee = FactoryGirl.create(:registered_user)
        followee.block!(follower)
        follower.follow!(followee)
        follower.should have(0).followers
      end

      context "#follow_all!" do
        it "can suppress duplicate follows" do
          followees = (1..2).map { FactoryGirl.create(:registered_user) }
          follower.follow_all!(followees)
          follower.follow_all!(followees)
          follower.followees.should have(2).people
        end
      end
    end

    it 'creates follow with optional attributes' do
      follower = FactoryGirl.create(:registered_user)
      followee = FactoryGirl.create(:registered_user)
      Follows::AfterCreationJob.expects(:enqueue).with(is_a(Integer), has_entry(notify_followee: false))
      follow = follower.follow!(followee, attrs: {suppress_followee_notifications: true})
    end
  end

  context "#unfollow!" do
    it "has 2 followers after 5 people follow and 3 unfollow" do
      user = FactoryGirl.create(:registered_user)
      followers = (1..5).collect do |i|
        follower = FactoryGirl.create(:registered_user)
        follower.follow!(user)
        follower
      end
      followers.take(3).each {|follower| follower.unfollow!(user)}
      user.followers.should have(2).followers
    end

    context "with a follower" do
      let(:follower) { FactoryGirl.create(:registered_user) }
      it "is following 3 people after 5 follows and 2 unfollows" do
        followees = (1..5).collect do |i|
          user = FactoryGirl.create(:registered_user)
          follower.follow!(user)
          user
        end
        followees.take(2).each {|followee| follower.unfollow!(followee)}
        follower.followees.should have(3).people
      end

      it "ignores an unfollow request for a user it is not following" do
        follower = FactoryGirl.create(:registered_user)
        followee = FactoryGirl.create(:registered_user)
        follower.following?(followee).should_not be_true
        follower.unfollow!(followee)
        follower.following?(followee).should_not be_true
      end
    end
  end

  describe "#follow_inviters!" do
    it "gets a list of inviters and follows them" do
      user = FactoryGirl.create(:registered_user)
      user_profile = stub('user-profile', id: 'deadbeef', person_id: user.person_id)
      inviter = FactoryGirl.create(:registered_user)
      inviter_profile = stub('inviter-profile', id: 'cafebebe', person_id: inviter.person_id)
      Invite.expects(:find_inviters_of_profile_uuid).with(user_profile.id).returns([inviter_profile])
      user.expects(:follow_all!).with([inviter])
      user.follow_inviters!(user_profile)
    end
  end

  context "#block!" do
    it "cancels follows" do
      user = FactoryGirl.create(:registered_user)
      follower = FactoryGirl.create(:registered_user)
      follower.follow!(user)
      user.followers.should have(1).follower
      user.expects(:track_usage).with(:block_user, user: user)
      user.block!(follower)
      user.reload
      user.followers.should have(0).followers
    end
  end

  context "#unblock!" do
    it "unblocks follows" do
      user = FactoryGirl.create(:registered_user)
      follower = FactoryGirl.create(:registered_user)
      user.block!(follower)
      user.expects(:track_usage).with(:unblock_user, user: user)
      user.unblock!(follower)
      follower.follow!(user)
      user.reload
      user.followers.should have(1).followers
    end
  end

  describe '#registered_followers' do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:followers) { FactoryGirl.create_list(:registered_user, 4) }
    before do
      followers.each_with_index.map { |f,i| Timecop.travel((10-i).minutes.ago) { f.follow!(user) } }
    end

    it 'sorts by id if no order provided' do
      expect(user.registered_followers).to eq(followers)
    end

    it 'sorts by descending create date if requested' do
      expect(user.registered_followers(order: :reverse_chron)).to eq(followers.reverse)
    end
  end

  describe '#registered_followees' do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:followees) { FactoryGirl.create_list(:registered_user, 4) }
    before do
      followees.each_with_index.map { |f,i| Timecop.travel((10-i).minutes.ago) { user.follow!(f) } }
    end

    it 'sorts by id if no order provided' do
      expect(user.registered_followees).to eq(followees)
    end

    it 'sorts by descending create date if requested' do
      expect(user.registered_followees(order: :reverse_chron)).to eq(followees.reverse)
    end
  end

  describe "#find_registered_person_ids_in_batches" do
    let!(:users) { FactoryGirl.create_list(:registered_user, 4) }
    let(:person_ids) { users.map(&:person_id) }
    let(:person_id_batches) { person_ids.each_slice(2) }

    it "calls block on person ids in batches" do
      expect { |b| User.find_registered_person_ids_in_batches(batch_size: 2, &b) }.to yield_successive_args(*person_id_batches)
    end
  end

  describe '::find_most_recent_registered_person_ids_in_batches' do
    def create_users(count)
      1.upto(count).map do |i|
        user = FactoryGirl.create(:registered_user)
        user.update_column(:registered_at, i.hours.ago)
        user
      end
    end

    context "when there is no overall limit" do
      context "and the total users fill up batches evenly" do
        let(:users) { create_users(4) }
        let(:person_id_batches) do
          [[users.first.person_id, users.second.person_id], [users.third.person_id, users.fourth.person_id]]
        end

        it "yields person ids in batches" do
          expect { |b| User.find_most_recent_registered_person_ids_in_batches(batch_size: 2, &b) }.
            to yield_successive_args(*person_id_batches)
        end
      end

      context "and the total users do not fill up batches evenly" do
        let(:users) { create_users(3) }
        let(:person_id_batches) do
          [[users.first.person_id, users.second.person_id], [users.third.person_id]]
        end

        it "yields person ids in batches" do
          expect { |b| User.find_most_recent_registered_person_ids_in_batches(batch_size: 2, &b) }.
            to yield_successive_args(*person_id_batches)
        end
      end
    end

    context "when there is an overall limit" do
      context "and there are more users than the overall limit" do
        context "and the limited users fill up batches evenly" do
          let(:options) { {batch_size: '2', limit: '4'} } # ensure that string values work
          let(:users) { create_users(6) }
          let(:person_id_batches) do
            [[users.first.person_id, users.second.person_id], [users.third.person_id, users.fourth.person_id]]
          end

          it "yields person ids in batches" do
            expect { |b| User.find_most_recent_registered_person_ids_in_batches(options, &b) }.
              to yield_successive_args(*person_id_batches)
          end
        end

        context "and the limited users do not fill up batches evenly" do
          let(:options) { {batch_size: 2, limit: 3} }
          let(:users) { create_users(6) }
          let(:person_id_batches) do
            [[users.first.person_id, users.second.person_id], [users.third.person_id]]
          end

          it "yields person ids in batches" do
            expect { |b| User.find_most_recent_registered_person_ids_in_batches(options, &b) }.
              to yield_successive_args(*person_id_batches)
          end
        end
      end

      context "and there are fewer users than the overall limit" do
        context "and the limited users fill up batches evenly" do
          let(:options) { {batch_size: 2, limit: 4} }
          let(:users) { create_users(2) }
          let(:person_id_batches) do
            [[users.first.person_id, users.second.person_id]]
          end

          it "yields person ids in batches" do
            expect { |b| User.find_most_recent_registered_person_ids_in_batches(options, &b) }.
              to yield_successive_args(*person_id_batches)
          end
        end

        context "and the limited users do not fill up batches evenly" do
          let(:options) { {batch_size: 2, limit: 4} }
          let(:users) { create_users(1) }
          let(:person_id_batches) do
            [[users.first.person_id]]
          end

          it "yields person ids in batches" do
            expect { |b| User.find_most_recent_registered_person_ids_in_batches(options, &b) }.
              to yield_successive_args(*person_id_batches)
          end
        end
      end
    end
  end

  describe "#generate_reset_password_token" do
    it "generates a token when the user is registered" do
      user = FactoryGirl.create(:registered_user)
      rv = User.generate_reset_password_token(user.email)
      rv.should have(:no).errors
      rv.reset_password_token.should be
    end

    it "does not generate a token when the user is not registered" do
      user = FactoryGirl.create(:connected_user)
      rv = User.generate_reset_password_token(user.email)
      rv.reset_password_token.should be_nil
    end

    it "sets an error when the email is blank" do
      rv = User.generate_reset_password_token(nil)
      rv.should have(1).error
    end

    it "sets an error when the email is not found" do
      rv = User.generate_reset_password_token('blahblahblah')
      rv.should have(1).error
    end
  end

  describe "#generate_reset_password_token!" do
    it "generates a reset password token when one isn't set" do
      user = FactoryGirl.create(:registered_user)
      user.generate_reset_password_token!
      user.reset_password_token.should_not be_nil
    end

    it "does not generate a reset password token when one is set" do
      token = "abcdef"
      user = FactoryGirl.create(:registered_user, :reset_password_token => token)
      user.generate_reset_password_token!
      user.reset_password_token.should == token
    end
  end

  describe "when resetting the password" do
    before(:each) do
      @token = "abcdef"
      @user = FactoryGirl.create(:registered_user, :reset_password_token => @token)
      @old_pwd = @user.encrypted_password
      new_pwd = 'new_pwd'
      @user.reset_password!(new_pwd, new_pwd)
    end

    it "resets the password" do
      @user.encrypted_password.should_not == @old_pwd
    end

    it "blanks the reset password token" do
      @user.reset_password_token.should be_nil
    end

    it "does not have errors" do
      @user.errors.should be_empty
    end
  end

  describe "when resetting the password with invalid attributes" do
    before(:each) do
      @token = "abcdef"
      @user = FactoryGirl.create(:registered_user, :reset_password_token => @token)
      @old_pwd = @user.encrypted_password
      @user.reset_password!("hi", "there")
    end

    it "does not reset the password" do
      @user.encrypted_password.should == @old_pwd
    end

    it "does not blank the reset password token" do
      @user.reset_password_token.should == @token
    end

    it "has errors" do
      @user.errors.should_not be_empty
    end
  end

  describe "when updating the password" do
    let :current_password do
      "test"
    end

    subject do
      FactoryGirl.create(:registered_user, :password => current_password, :password_confirmation => current_password)
    end

    before { subject.validate_completely! }

    it "can update the password if the current password is provided" do
      subject.current_password = current_password
      subject.password = "success"
      subject.password_confirmation = "success"

      subject.should be_valid
    end

    it "can't update the password unless it provides the current password" do
      subject.current_password = ""
      subject.password = "fail"
      subject.password_confirmation = "fail"

      subject.should_not be_valid
      subject.errors[:current_password].should_not be_empty
    end

    it "can't update the password unless it provides the *correct* current password" do
      subject.current_password = "not the one"
      subject.password = "fail"
      subject.password_confirmation = "fail"

      subject.should_not be_valid
      subject.errors[:current_password].should_not be_empty
    end

    it "checks password confirmation" do
      subject.current_password = current_password
      subject.password = "fail"
      subject.password_confirmation = ""

      subject.should_not be_valid
      subject.errors[:current_password].should be_empty
      # Why doesn't rails store the error in the password_confirmation field? ¬¬
      subject.errors[:password].should_not be_empty
    end

    it "doesn't allow blank passwords" do
      subject.current_password = current_password
      subject.password = ""
      subject.password_confirmation = ""

      subject.should_not be_valid
      subject.errors[:current_password].should be_empty
      subject.errors[:password].should_not be_empty
    end

    it "doesn't try to validate the password if you only update non-related attributes" do
      subject.email = "kat@galactica.mil"
      subject.password = nil
      subject.password_confirmation = nil
      subject.current_password = nil

      # FIXME: Figure out a better way to test that the validations aren't
      # triggered, not that it doesn't have errors...
      subject.valid? # trigger the validations
      subject.errors[:password].should be_empty
      subject.errors[:password_confirmation].should be_empty
      subject.errors[:current_password].should be_empty
    end

    it "can register connected users without raising validation problems" do
      user = FactoryGirl.create(:connected_user)
      user.password = "test"
      user.password_confirmation = "test"

      user.should be_valid
    end
  end

  describe 'when updating account details' do
    context 'for a guest' do
      subject { FactoryGirl.create(:guest_user) }

      it "allows blank first name" do
        subject.firstname = ''
        subject.should be_valid
        subject.errors.should be_empty
      end

      it "allows blank last name" do
        subject.lastname = ''
        subject.should be_valid
        subject.errors.should be_empty
      end

      it "allows blank name" do
        subject.name = ''
        subject.should be_valid
        subject.errors.should be_empty
      end

      it "allows blank slug" do
        subject.slug = ''
        subject.should be_valid
        subject.errors.should be_empty
      end
    end

    context 'for a connected user' do
      subject { FactoryGirl.create(:connected_user) }

      it "doesn't allow blank first name" do
        subject.firstname = ''
        subject.should_not be_valid
        subject.should have(1).errors_on(:firstname)
      end

      it "allows blank last name" do
        subject.lastname = ''
        subject.should be_valid
        subject.errors.should be_empty
      end

      it "doesn't allow blank name" do
        subject.name = ''
        subject.should_not be_valid
        subject.should have(1).errors_on(:name)
      end

      it "allows blank slug" do
        subject.slug = ''
        subject.should be_valid
        subject.errors.should be_empty
      end
    end

    context 'for a registered user' do
      subject { FactoryGirl.create(:registered_user) }

      it "doesn't allow blank first name" do
        subject.firstname = ''
        subject.should_not be_valid
        subject.should have(1).errors_on(:firstname)
      end

      it "allows blank last name" do
        subject.lastname = ''
        subject.should be_valid
        subject.errors.should be_empty
      end

      it "doesn't allow blank name" do
        subject.name = ''
        subject.should_not be_valid
        subject.should have(1).errors_on(:name)
      end

      it "doesn't allow blank slug" do
        subject.slug = ''
        subject.should_not be_valid
        subject.should have(1).errors_on(:slug)
      end
    end
  end

  describe "#destroy" do
    let(:profiles) { [] }
    before do
      Anchor::User.stubs(:destroy!)
      Lagunitas::User.stubs(:destroy!)
      Pyramid::User.stubs(:destroy!)
      Profile.stubs(:find_all_for_person!).returns(profiles)
    end

    subject { FactoryGirl.create(:registered_user) }

    it "destroys email accounts" do
      email_account = FactoryGirl.create(:email_account, :user => subject)
      FactoryGirl.create(:contact, :email_account => email_account)
      subject.email_accounts.should_not be_empty
      subject.destroy
      subject.email_accounts.reload
      subject.email_accounts.should be_empty
    end

    it "destroys follows" do
      FactoryGirl.create(:registered_user).follow!(subject)
      subject.follows.should_not be_empty
      subject.destroy
      subject.follows.reload
      subject.follows.should be_empty
    end

    it "destroys follow tombstones" do
      follow = FactoryGirl.create(:registered_user).follow!(subject)
      follow.destroy
      subject.follow_tombstones.should_not be_empty
      subject.destroy
      subject.follow_tombstones.reload
      subject.follow_tombstones.should be_empty
    end

    it "destroys followings" do
      subject.follow!(FactoryGirl.create(:registered_user))
      subject.followings.should_not be_empty
      subject.destroy
      subject.followings.reload
      subject.followings.should be_empty
    end

    it "destroys following tombstones" do
      following = subject.follow!(FactoryGirl.create(:registered_user))
      following.destroy
      subject.following_tombstones.should_not be_empty
      subject.destroy
      subject.following_tombstones.reload
      subject.following_tombstones.should be_empty
    end

    it "destroys seller listings" do
      BankAccount.any_instance.stubs(:skip_invalidate).returns(true)
      listing = FactoryGirl.create(:sold_listing, :seller => subject)
      FactoryGirl.create(:settled_order, :listing => listing)
      subject.seller_listings.should_not be_empty
      subject.destroy
      subject.seller_listings.reload
      subject.seller_listings.should be_empty
    end

    it "destroys buyer listings" do
      BankAccount.any_instance.stubs(:skip_invalidate).returns(true)
      listing = FactoryGirl.create(:sold_listing)
      FactoryGirl.create(:settled_order, :listing => listing, :buyer => subject)
      subject.buyer_listings.should_not be_empty
      subject.destroy
      subject.buyer_listings.reload
      subject.buyer_listings.should be_empty
    end

    it "destroys postal addresses" do
      FactoryGirl.create(:shipping_address, :user => subject)
      subject.postal_addresses.should_not be_empty
      subject.destroy
      subject.postal_addresses.reload
      subject.postal_addresses.should be_empty
    end

    it "destroys order ratings" do
      listing = FactoryGirl.create(:sold_listing)
      order = FactoryGirl.create(:complete_order, :listing => listing, :buyer => subject)
      subject.order_ratings.should_not be_empty
      subject.destroy
      subject.order_ratings.reload
      subject.order_ratings.should be_empty
    end

    context 'with service data' do
      context 'with no service errors' do
        before do
          Anchor::User.expects(:destroy!).with(subject.id)
          Lagunitas::User.expects(:destroy!).with(subject.id)
          Pyramid::User.expects(:destroy!).with(subject.id)
          Profile.expects(:find_all_for_person!).with(subject.person_id).returns(profiles)
        end

        it 'succeeds' do
          subject.destroy
          expect(User.where(id: subject.id)).to have(0).users
        end

        context 'with profiles' do
          let(:profile) { stub('profile') }
          let(:profiles) { [profile] }

          it 'unregisters each profile' do
            profile.expects(:unregister!)
            subject.destroy
          end
        end
      end

      context 'when a service error occurs' do
        before { Anchor::User.expects(:destroy!).with(subject.id).raises(Exception.new) }

        it 'does not destroy user' do
          subject.destroy
          expect(User.where(id: subject.id)).to have(1).user
        end
      end
    end
  end

  describe "creating shipping addresses" do
    let (:user) { FactoryGirl.create(:registered_user) }

    it "should throw a validation error when creating two addresses whose names vary only by case" do
      address = FactoryGirl.attributes_for(:postal_address)
      user.shipping_addresses.build(address.merge(:name => 'foo')).save!
      expect { user.shipping_addresses.build(address.merge(:name => 'Foo')).save! }.
        to raise_error(ActiveRecord::RecordInvalid)
    end

    it "should allow mass attribute updates for shipping addresses" do
      address = FactoryGirl.attributes_for(:shipping_address, :name => 'foobar')
      user.postal_addresses_attributes = {'0' => address}
      user.save!
      user.reload
      user.shipping_addresses.first.name.should == 'foobar'

      user.postal_addresses_attributes =
        {'0' => address.merge(:name => 'fuzbaz', :id => user.shipping_addresses.first.id)}
      user.save!
      user.reload
      user.shipping_addresses.first.name.should == 'fuzbaz'
    end

    it "should allow different users to create postal addresses with the same name" do
      user2 = FactoryGirl.create(:registered_user)
      address = FactoryGirl.attributes_for(:postal_address)
      [user, user2].each do |u|
        u.shipping_addresses.build(address)
        u.save!
      end
    end
  end

  describe "updating default shipping addresses" do
    let (:user) { FactoryGirl.create(:registered_user) }

    it "sets the default state for a postal address" do
      address = FactoryGirl.attributes_for(:postal_address)
      user.shipping_addresses.build(address.merge(:name => 'foo')).save!
      user.postal_addresses.first.default!
      user.reload
      user.shipping_addresses.first.default_address.should == true
    end

    it "sets the default to false for an existing default address" do
      address = FactoryGirl.attributes_for(:postal_address)
      user.shipping_addresses.build(address.merge(:name => 'foo', :default_address => true)).save!
      user.shipping_addresses.build(address.merge(:name => 'bar')).save!
      user.postal_addresses.where(name: 'bar').first.default!
      user.reload
      user.shipping_addresses.where(name: 'foo').first.default_address.should == false
      user.shipping_addresses.where(name: 'bar').first.default_address.should == true
    end
  end

  it "authenticates when the encrypted password matches" do
    user = FactoryGirl.create(:registered_user)
    user.password = 'test'
    user.encrypt_password
    user.authenticates?('test').should == user
  end

  it "does not authenticate when the encrypted password does not match" do
    user = User.new(:password => 'test')
    user.encrypt_password
    user.authenticates?('blah').should be_nil
  end

  it "does not authenticate when there's no encrypted password" do
    user = User.new
    user.authenticates?('foobar').should be_nil
  end

  it "does not authenticate a user that is not registered" do
    user = FactoryGirl.create(:inactive_user)
    User.authenticate(user.email, user.password).should be_false
  end

  it "generates a remember timestamp when remembering if one does not exist" do
    user = FactoryGirl.create(:registered_user)
    user.remember_created_at.should be_nil
    user.remember_me!
    user.remember_created_at.should be
  end

  it "generates a new remember timestamp when remembering if the existing one is expired" do
    original = 10.years.ago
    user = FactoryGirl.create(:registered_user, remember_created_at: original)
    user.remember_created_at.should == original
    user.remember_me!
    user.remember_created_at.should be
    user.remember_created_at.should_not == original
  end

  it "removes the remember timestamp when forgetting" do
    user = FactoryGirl.create(:registered_user, remember_created_at: 1.day.ago)
    user.remember_created_at.should be
    user.forget_me!
    user.remember_created_at.should be_nil
  end

  describe "#absorb_guest!" do
    let!(:guest) { FactoryGirl.create(:guest_user) }
    let!(:user) { FactoryGirl.create(:registered_user) }
    let!(:listing) { FactoryGirl.create(:inactive_listing, seller: guest) }

    before do
      Anchor::User.stubs(:destroy!)
      Lagunitas::User.stubs(:destroy!)
      Pyramid::User.stubs(:destroy!)
      Profile.stubs(:find_all_for_person!).returns([])
    end

    it "merges the guest's listings" do
      guest.seller_listings.should have(1).listing
      user.seller_listings.should have(0).listings
      user.absorb_guest!(guest)
      guest.seller_listings.reload
      user.seller_listings.reload
      guest.seller_listings.should have(0).listing
      user.seller_listings.should have(1).listings
    end

    it "destroys the guest" do
      user.absorb_guest!(guest)
      lambda { User.find(guest.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#find_expired_guests" do
    let!(:old_guest) { FactoryGirl.create(:guest_user) }
    let!(:registered_user) { FactoryGirl.create(:registered_user) }

    it "should find old guests" do
      Timecop.travel(Time.zone.now + User.guest_user_lifetime + 1.minute) do
        new_guest = FactoryGirl.create(:guest_user)
        users = User.find_expired_guests
        users.should include old_guest
        users.should_not include registered_user
        users.should_not include new_guest
      end
    end
  end

  describe "#deactivate!" do
    let(:user) { FactoryGirl.create(:registered_user) }

    [:active, :inactive, :suspended].each do |state|
      it "cancels #{state} listings" do
        listing = FactoryGirl.create(:active_listing, seller: user)
        user.deactivate!
        listing.reload.should be_cancelled
      end
    end

    it 'deletes incomplete listings' do
      listing = FactoryGirl.create(:incomplete_listing, seller: user)
      user.deactivate!
      lambda { listing.reload }.should raise_error ActiveRecord::RecordNotFound
    end

    context 'when the user has unfinalized orders that prevent listing cancellation' do
      #XXX: add :return_pending, :return_shipped, :return_delivered once we fix returns
      [:confirmed, :shipped, :delivered, :complete].each do |state|
        it "like #{state}, it should fail" do
          order = FactoryGirl.create("#{state}_order")
          order.listing.seller.deactivate.should be_false
          order.buyer.deactivate.should be_false
          order.listing.should_not be_cancelled
        end
      end
    end

    context 'when the user has only finalized orders' do
      #XXX: add return_complete once we fix returns
      [:settled, :cancelled].each do |state|
        it "like #{state}, should succeed" do
          order = FactoryGirl.create("#{state}_order")
          order.listing.seller.deactivate.should be_true
          # canceled orders don't have buyers
          order.buyer.deactivate.should be_true if order.buyer
        end
      end
    end

    context 'when the user has only orders with cancellable listings' do
      #XXX: add return_complete once we fix returns
      [:pending].each do |state|
        it "like #{state}, seller cancellation should succeed since the listing will be cancelled" do
          FactoryGirl.create("#{state}_order").listing.seller.deactivate.should be_true
        end

        it "like #{state}, buyer cancellation should fail" do
          FactoryGirl.create("#{state}_order").listing.buyer.deactivate.should be_false
        end
      end
    end

    it "destroys follows" do
      FactoryGirl.create(:registered_user).follow!(user)
      user.follows.should_not be_empty
      user.deactivate!
      user.follows.reload
      user.follows.should be_empty
    end

    it "destroys followings" do
      user.follow!(FactoryGirl.create(:registered_user))
      user.followings.should_not be_empty
      user.deactivate!
      user.followings.reload
      user.followings.should be_empty
    end

    it 'clears recent listings caches' do
      user.recent_listing_ids << 123
      user.recent_listed_listing_ids << 456
      user.recent_saved_listing_ids << 789
      user.deactivate!
      user.recent_listing_ids.values.should be_empty
      user.recent_listed_listing_ids.values.should be_empty
      user.recent_saved_listing_ids.values.should be_empty
    end
  end

  describe '#unfinalized_orders' do
    it 'should return complete and canceled orders' do
      user = Factory.create(:registered_user)
      finalized_orders = [:settled, :cancelled].map do |state|
        FactoryGirl.create("#{state}_order", listing: FactoryGirl.create(:active_listing, seller: user))
        FactoryGirl.create("#{state}_order", listing: FactoryGirl.create(:active_listing), buyer: user)
      end
      unfinalized_orders = [:pending, :confirmed, :shipped, :delivered, :complete].map do |state|
        FactoryGirl.create("#{state}_order", listing: FactoryGirl.create(:active_listing, seller: user))
        FactoryGirl.create("#{state}_order", listing: FactoryGirl.create(:active_listing), buyer: user)
      end
      unfinalized_orders.each { |l| user.unfinalized_orders.should include(l) }
      finalized_orders.each { |l| user.unfinalized_orders.should_not include(l) }
    end
  end

  describe '#registered_before' do
    let!(:new_user) { FactoryGirl.create(:registered_user) }
    let!(:old_user) do
      user = nil
      Timecop.travel(5.days.ago) { user = FactoryGirl.create(:registered_user) }
      user
    end
    subject { User.registered_before(4.days.ago) }
    it { should have(1).user }
    it { should == [old_user] }
  end

  describe '#count_by_state' do
    before do
      3.times { FactoryGirl.create(:registered_user) }
      2.times { FactoryGirl.create(:guest_user) }
      FactoryGirl.create(:connected_user)
    end
    subject { User.count_by_state }
    it { should == { 'registered' => 3, 'guest' => 2, 'connected' => 1 } }
  end

  describe '#registrations_by_day' do
    days = [1,4,7]
    before { days.each { |i| Timecop.travel(Time.now.utc - i.days) { FactoryGirl.create(:registered_user) } } }
    subject { User.registrations_by_day(10) }

    context "for days with registrations" do
      days.each do |d|
        it "has a registration #{d} days ago" do
          subject[(Time.now.utc - d.days).to_date].should == 1
        end
      end
    end

    context "for days without registrations" do
      ((0..9).to_a - days).each do |d|
        it "has no registration #{d} days ago" do
          subject[(Time.now.utc - d.day).to_date].should == 0
        end
      end
    end
  end

  describe '#published_listing_count' do
    subject { FactoryGirl.create(:registered_user) }

    context "with only incomplete listings" do
      before { FactoryGirl.create(:incomplete_listing, seller: subject) }
      its(:published_listing_count) { should == 0 }
    end

    context "with only inactive listings" do
      before { FactoryGirl.create(:inactive_listing, seller: subject) }
      its(:published_listing_count) { should == 0 }
    end

    context "with an active and an incomplete listing" do
      before do
        FactoryGirl.create(:incomplete_listing, seller: subject)
        FactoryGirl.create(:active_listing, seller: subject)
      end
      its(:published_listing_count) { should == 1 }
    end

    context "with an active and a sold listing" do
      before { FactoryGirl.create(:active_listing, seller: subject) }
      before { FactoryGirl.create(:sold_listing, seller: subject) }
      its(:published_listing_count) { should == 2 }
    end
  end

  it "orders users by following and followers" do
    me = FactoryGirl.create(:registered_user)
    # I am not following liker 1, and he has no followers
    liker1 = FactoryGirl.create(:registered_user)
    # I am not following liker 2, and he has followers
    liker2 = FactoryGirl.create(:registered_user)
    FactoryGirl.create(:registered_user).follow!(liker2)
    # I am following liker 3, and he has no followers
    liker3 = FactoryGirl.create(:registered_user)
    me.follow!(liker3)
    # I am following liker 4, and he has followers
    liker4 = FactoryGirl.create(:registered_user)
    me.follow!(liker4)
    FactoryGirl.create(:registered_user).follow!(liker4)
    # liker 5 is not active
    liker5 = FactoryGirl.create(:inactive_user)
    users = me.find_ordered_by_following_and_followers([liker1.id, liker2.id, liker3.id, liker4.id, liker5.id])
    users.should have(4).users
    users[0].should == liker4
    users[1].should == liker3
    users[2].should == liker2
    users[3].should == liker1
  end

  it "orders users by followers" do
    # liker 1 has no followers
    liker1 = FactoryGirl.create(:registered_user)
    # liker 2 has 2 followers
    liker2 = FactoryGirl.create(:registered_user)
    FactoryGirl.create(:registered_user).follow!(liker2)
    FactoryGirl.create(:registered_user).follow!(liker2)
    # liker 3 has 1 follower
    liker3 = FactoryGirl.create(:registered_user)
    FactoryGirl.create(:registered_user).follow!(liker3)
    # liker 4 is not active
    liker4 = FactoryGirl.create(:inactive_user)
    users = User.find_ordered_by_followers([liker1.id, liker2.id, liker3.id, liker4.id])
    users.should have(3).users
    users[0].should == liker2
    users[1].should == liker3
    users[2].should == liker1
  end

  context "sharing" do
    subject { FactoryGirl.create(:registered_user) }
    let(:profile) { stub('profile', feed_postable?: true, first_name: 'Ham', network: :facebook) }
    before { subject.person.stubs(:network_profiles).returns({facebook: profile}) }

    describe "#publish_signup!" do
      it "should schedule a delayed job to publish to an external network" do
        PublishSignup.expects(:enqueue_at).once
        subject.publish_signup!
      end
    end

    describe "#share_follow!" do
      let(:followee) { FactoryGirl.create(:registered_user) }
      it "posts to the facebook feed" do
        subject.follow!(followee)
        profile.expects(:post_to_feed).with(has_entries name: 'Ham is following test user on Copious', link: 'http://awesome.com/hats')
        subject.expects(:track_usage).with(:share_follow_user, user: subject)
        subject.share_follow!(followee, :facebook, 'http://awesome.com/hats')
      end

      it "throws an exception if user is not following followee" do
        expect { subject.share_follow!(followee, :facebook) }.to raise_exception(ArgumentError)
      end
    end
  end

  context "credit methods" do
    subject { FactoryGirl.create(:registered_user) }

    describe "#has_available_credit?" do
      it "should be false if the user does not have credit" do
        subject.credits.should == []
        subject.has_available_credit?.should be_false
      end

      it "should be true if the user has credit" do
        FactoryGirl.create(:credit, user: subject)
        subject.has_available_credit?.should be_true
      end

      it "should be false if the user does not have available credit" do
        FactoryGirl.create(:credit, user: subject, expires_at: Time.now - 30)
        subject.has_available_credit?.should be_false
      end

      context "for a specific listing" do
        let(:offer_seller) { Factory.create(:registered_user) }
        let(:offer_listing) { Factory.create(:active_listing, seller_id: offer_seller.id) }
        let(:offerless_listing) { Factory.create(:active_listing) }
        let(:offer) do
          o = Factory.create(:offer)
          o.seller_ids = [offer_seller.id]
          o
        end
        let!(:offer_credit) { Factory.create(:credit, amount: 1.0, user: subject, expires_at: nil, offer_id: offer.id)}

        before do
          Offer.stubs(:all).returns([offer])
        end

        context "when the listing has an associated offer" do
          it "should have available credit" do
            subject.has_available_credit?(listing: offer_listing).should be_true
          end
        end

        context "when all credits are associated with different listings" do
          it "should not have available credit" do
            subject.has_available_credit?(listing: offerless_listing).should be_false
          end
        end
      end
    end
  end

  describe "#all_registered_network_followers" do
    let(:f1) { Factory.create(:registered_user) }
    let(:f2) { Factory.create(:registered_user) }
    let(:f3) { Factory.create(:registered_user) }

    it "returns unique registered followers" do
      np = {
        facebook: stub('facebook', followers: [
          stub('facebook1', person_id: f1.person_id),
          stub('facebook2', person_id: f2.person_id),
        ]),
        twitter: stub('twitter', followers: [
          stub('twitter1', person_id: f1.person_id),
        ]),
      }
      subject.person.expects(:network_profiles).returns(np)
      followers = subject.all_registered_network_followers
      followers.should have(2).followers
      followers.should include(f1, f2)
    end
  end

  describe "#formatted_mailable_addresses" do
    let!(:active_user) { FactoryGirl.create(:registered_user, name: 'Justin Bieber', email: 'justin@bieber.com') }
    let!(:inactive_user) { FactoryGirl.create(:inactive_user, email: 'adam@lavine.com') }
    let(:emails) { ['justin@bieber.com', 'adam@lavine.com', 'taylor@swift.com'] }

    subject { User.formatted_mailable_addresses(emails) }

    it { should have(2).items }
    it { should include('Justin Bieber <justin@bieber.com>', 'taylor@swift.com') }
  end

  describe '#each_interested_user' do
    subject { FactoryGirl.create(:registered_user) }
    let!(:follows) { FactoryGirl.create_list(:follow, 4, user: subject) }
    let(:followers) { follows.map(&:follower) }
    let(:follower_id_batches) { followers.each_slice(2).map { |batch| batch.map(&:id) } }
    let(:preferences) { followers.each_with_object({}) { |f,m| m[f.id] = stub('preferences') } }
    let(:preference_batches) { follower_id_batches.map { |ids| preferences.slice(*ids) } }
    let(:args) { followers.map { |f,i| [f, preferences[f.id]] } }
    before do
      User.expects(:preferences).twice.returns(preference_batches.first).then.returns(preference_batches.last)
    end

    it 'yields users one at a time' do
      expect { |b| subject.each_interested_user(with_prefs: true, batch_size: 2, &b) }.to yield_successive_args(*args)
    end
  end

  describe '#interested_user_ids' do
    subject { FactoryGirl.create(:registered_user) }
    let!(:follow) { FactoryGirl.create(:follow, user: subject) }

    it "should return user's id and followers' ids" do
      subject.interested_user_ids.should include(subject.id, follow.follower.id)
    end
  end

  describe '#ids_of_users_in_states' do
    let(:users) { (1..3).map {|i| FactoryGirl.create(:registered_user)} }
    let!(:user_ids) { users.map(&:id) }

    it 'should return ids for registered users' do
      User.ids_of_users_in_states(user_ids, :registered).should == user_ids
    end

    it 'should exclude non-registered users' do
      connected = FactoryGirl.create(:connected_user)
      new_user_ids = user_ids.dup
      new_user_ids << connected.id
      User.ids_of_users_in_states(new_user_ids, :registered).should == user_ids
    end
  end

  describe '#following_follows_for' do
    let(:user) { FactoryGirl.create(:registered_user) }
    let(:followees) { (1..2).map {|i| FactoryGirl.create(:registered_user)} }
    before { followees.each {|f| user.follow!(f) } }
    subject { user.following_follows_for([followees[0]]) }
    it { should == Follow.where(follower_id: user.id).where(user_id: followees[0].id).all }
  end

  describe '#formatted_email' do
    it 'should return an rfc822 valid address' do
      FactoryGirl.create(:registered_user, firstname: 'Ham', lastname: 'Sausages', email: 'ham@example.com').
        formatted_email.should == 'Ham Sausages <ham@example.com>'
      FactoryGirl.create(:registered_user, firstname: '/\l\l', lastname: '\/l-l', email: 'ham2@example.com').
        formatted_email.should == '"/\l\l \/l-l" <ham2@example.com>'
      FactoryGirl.create(:registered_user, firstname: 'Ha"m', lastname: 'Sausages', email: 'ham3@example.com').
        formatted_email.should == '"Ha\"m Sausages" <ham3@example.com>'
    end
  end

  describe '#create_registered_user' do
    it 'should succeed' do
      user = User.create_registered_user(firstname: 'Larry', lastname: 'Sanders', email: 'larry@example.com',
        password: 'beefcake', password_confirmation: 'beefcake')
      user.should be_registered
      user.errors.should be_empty
      # persisted? would return true even if a failed state transition subsequently rolled back the insert, so we
      # reload to verify the record was actually saved
      expect { user.reload }.to_not raise_error
    end

    it 'should fail when user is not connectable' do
      user = User.create_registered_user({})
      user.should_not be_registered
      user.errors.should_not be_empty
      # persisted? would treturn rue even if a failed state transition subsequently rolled back the insert, so we
      # reload to verify the record was not saved
      expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should fail when user is not registerable' do
      user = User.create_registered_user(firstname: 'Larry')
      user.should_not be_registered
      user.errors.should_not be_empty
      # persisted? would treturn rue even if a failed state transition subsequently rolled back the insert, so we
      # reload to verify the record was not saved
      expect { user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'has_ever_activated_a_listing?' do
    subject { FactoryGirl.create(:registered_user) }
    let(:listing) { FactoryGirl.create(:inactive_listing, seller: subject) }

    it 'should be false if the user has never activated a listing' do
      subject.has_ever_activated_a_listing?.should be_false
    end

    it 'should be true if the user has activated a listing' do
      listing.activate!
      subject.has_ever_activated_a_listing?.should be_true
    end

    it 'should be true if the user has activated a listing and deactivated it' do
      listing.activate!
      listing.deactivate!
      subject.has_ever_activated_a_listing?.should be_true
    end
  end

  describe '#add_interest_in' do
    subject { FactoryGirl.create(:registered_user) }
    let(:interest) { FactoryGirl.create(:interest, name: "Amp'd Jemimah") }
    let(:invalid_interest) { FactoryGirl.build(:interest, name: nil) }

    it 'should create an interest associated with this user' do
      subject.expects(:track_usage).with(:add_interest, user: subject, interest_name: interest.name)
      subject.add_interest_in!(interest)
      subject.interests.should include(interest)
    end

    it 'should not create a duplicate user interest' do
      existing = FactoryGirl.create(:user_interest, user_id: subject.id, interest: interest)
      ui = subject.add_interest_in!(interest)
      ui.should == existing
      subject.interests.should == [ui.interest]
    end
  end

  describe '#find_shared_interests' do
    it 'returns a shared interest' do
      ui1 = FactoryGirl.create(:user_interest)
      ui2 = FactoryGirl.create(:user_interest, interest: ui1.interest)
      expect(ui1.user.find_shared_interests(ui2.user)).to include(ui1.interest)
    end

    it 'returns nothing when there is no shared interest' do
      ui1 = FactoryGirl.create(:user_interest)
      ui2 = FactoryGirl.create(:user_interest)
      expect(ui1.user.find_shared_interests(ui2.user)).to be_empty
    end
  end

  describe '#find_random_shared_interests' do
    it 'returns a shared interest for each user' do
      ui1 = FactoryGirl.create(:user_interest)
      ui2 = FactoryGirl.create(:user_interest, interest: ui1.interest)
      ui3 = FactoryGirl.create(:user_interest, interest: ui1.interest)
      expect(ui1.user.find_random_shared_interests([ui2.user, ui3.user])).
        to eq({ui2.user.id => ui1.interest, ui3.user.id => ui1.interest})
    end

    it 'returns nothing when there is no shared interest' do
      ui1 = FactoryGirl.create(:user_interest)
      ui2 = FactoryGirl.create(:user_interest)
      ui3 = FactoryGirl.create(:user_interest)
      expect(ui1.user.find_random_shared_interests([ui2.user, ui3.user])).to be_empty
    end
  end
end
