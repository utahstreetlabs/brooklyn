require 'spec_helper'

describe People::Shareable do
  class FeedPostingPerson
    include People::Shareable
    attr_reader :id, :logger, :user

    def initialize(id, user)
      @id = id
      @user = user
      @logger = Rails.logger
    end
  end

  class Listing
    def self.photos_stored_remotely?
      false
    end
  end

  class User
    def self.photos_stored_remotely?
      false
    end
  end

  subject { FeedPostingPerson.new(123, stub('posting person', id: 123)) }

  let(:seller) { stub_user('Ren Faire Nerd', person: stub_person('ren-faire-nerd-person')) }
  let(:listing) do
    stub_listing('4-String Mountain Hourglass Solid Walnut HC1HB Dulcimer', seller: seller)
  end
  let(:listing_url) { 'http://suck.it/' }
  let(:user) { stub_user('Tom Waits', person: stub_person('tom-waits-person')) }
  let(:user_url) { 'http://eff.it/' }
  let(:network) { :facebook }
  let(:profile) { stub_network_profile 'black-francis', :facebook, name: 'Black Francis' }

  describe "#share_listing_activated" do
    it "posts to the feed" do
      subject.expects(:share_listing_event).with(:listing_activated, network, listing, listing_url).returns(true)
      subject.share_listing_activated(network, listing, listing_url)
    end
  end

  describe "#share_listing_liked" do
    it "posts to the feed" do
      subject.expects(:share_listing_event).
        with(:listing_liked, network, listing, listing_url, {},
             has_entry(other_user_profile: seller.person.for_network(network))).
        returns(true)
      subject.share_listing_liked(network, listing, listing_url)
    end

    it "does not post if the like was already shared on the network" do
      subject.expects(:share_listing_event).never
      subject.share_listing_liked(network, listing, listing_url, {shared: :facebook})
    end
  end

  describe "#share_listing_commented" do
    it "posts to the feed" do
      comment_text = "Hey citrus, hey liquor, I love it when you come together"
      subject.expects(:share_listing_event).
        with(:listing_commented, network, listing, listing_url, has_entry(comment: comment_text),
             has_entry(other_user_profile: seller.person.for_network(network))).
        returns(true)
      subject.share_listing_commented(network, listing, listing_url, comment_text)
    end
  end

  describe "#share_user_followed" do
    it "posts to the feed" do
      subject.expects(:share_user_event).
        with(:user_followed, network, user, user_url, {},
             has_entry(other_user_profile: user.person.for_network(network))).
        returns(true)
      subject.share_user_followed(network, user, user_url)
    end
  end

  describe "#share_listing_event" do
    let(:event) { :listing_activated }

    it "posts to the feed" do
      subject.expects(:for_network).with(network).returns(profile)
      params = {firstname: profile.first_name, listing: listing.title, listing_id: listing.id, link: listing_url,
        picture: "http:#{listing.photos.first.version_url(:small)}", foo: :bar,
        other_user_username: seller.person.for_network(network).username}
      options = {other_user_profile: seller.person.for_network(network)}
      subject.expects(:share_event).with(event, profile, params, options)
      subject.share_listing_event(event, network, listing, listing_url, params, options)
    end

    it "barfs when the user does not have a profile for the given network" do
      subject.expects(:for_network).with(network).returns(nil)
      subject.expects(:share_event).never
      expect { subject.share_listing_event(event, network, listing, listing_url) }.to raise_error(ArgumentError)
    end
  end

  describe "#share_user_event" do
    let(:event) { :user_followed }

    it "posts to the feed" do
      subject.expects(:for_network).with(network).returns(profile)
      params = {firstname: profile.first_name, other_user: user.name, other_user_id: user.id, link: user_url, foo: :bar,
        other_user_username: user.person.for_network(network).username}
      options = {other_user_profile: user.person.for_network(network)}
      subject.expects(:share_event).with(event, profile, params, options)
      subject.share_user_event(event, network, user, user_url, {foo: :bar}, options)
    end

    it "barfs when the user does not have a profile for the given network" do
      subject.expects(:for_network).with(network).returns(nil)
      subject.expects(:share_event).never
      expect { subject.share_user_event(event, network, user, user_url) }.to raise_error(ArgumentError)
    end
  end

  describe "#share_event" do
    let(:event) { :something }
    let(:params) { {} }
    let(:options) { {} }
    let(:sharing_options) { {} }

    before do
      subject.class.expects(:sharing_options!).with(event, profile.network, params, options).returns(sharing_options)
    end

    it "post to the profile's feed" do
      profile.expects(:post_to_feed).with(sharing_options).returns(true)
      subject.expects(:track_usage)
      subject.share_event(event, profile, params, options).should be_true
    end

    it "fails to post to the feed" do
      profile.expects(:post_to_feed).with(sharing_options).returns(false)
      subject.expects(:track_usage)
      subject.share_event(event, profile, params, options).should be_false
    end
  end

  describe "#sharing_options" do
    it "generates message options" do
      event = :listing_activated
      network = :facebook
      params = {firstname: 'Krusty', listing: 'Big Red Nose'}
      options = {}
      sharing_options = {}
      Network::Facebook.expects(:message_options!).
        with(:share_listing_activated, params, options).
        returns(sharing_options)
      FeedPostingPerson.sharing_options!(:listing_activated, network, params, options).should == sharing_options
    end
  end
end
