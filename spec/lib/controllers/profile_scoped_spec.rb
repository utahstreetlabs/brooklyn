require 'spec_helper'

describe Controllers::ProfileScoped do
  class ProfileScopedController
    def self.helper_method(*args); end
    def self.before_filter(*args); end

    attr_reader :params, :logger
    attr_accessor :current_user

    def initialize
      @params = {}
      @current_user = nil
      @logger = Rails.logger
    end

    def anonymous_user?
      @current_user.nil?
    end

    include Controllers::ProfileScoped
  end

  subject { ProfileScopedController.new }

  let(:profile_user) { stub_user 'Stephen Merchant' }
  let(:viewer) { stub_user 'Ricky Gervais'}

  describe '#load_profile_user' do
    it 'should load the user given an id' do
      subject.params[:id] = profile_user.id
      User.expects(:find_by_slug!).with(profile_user.id).returns(profile_user)
      subject.send(:load_profile_user).should == profile_user
    end

    it 'should load the user given a public profile id' do
      subject.params[:public_profile_id] = profile_user.id
      User.expects(:find_by_slug!).with(profile_user.id).returns(profile_user)
      subject.send(:load_profile_user).should == profile_user
    end
  end

  describe '#require_registered_profile_user' do
    before do
      subject.instance_variable_set('@profile_user', profile_user)
    end

    it 'should allow the request when the profile user is registered' do
      subject.expects(:respond_not_found).never
      subject.send(:require_registered_profile_user)
    end

    it 'should deny the request when the profile user is not registered' do
      profile_user.stubs(:registered?).returns(false)
      subject.expects(:respond_not_found)
      subject.send(:require_registered_profile_user)
    end
  end

  describe '#listings_count' do
    it 'returns the count of visible listings by the profile user' do
      subject.instance_variable_set('@profile_user', profile_user)
      listings_count = 5
      profile_user.expects(:visible_listings_count).once.returns(listings_count)
      subject.send(:listings_count).should == listings_count
      # second time should be cached
      subject.send(:listings_count).should == listings_count
    end
  end

  describe '#liked_count' do
    it 'returns the count of listings liked by the profile user' do
      subject.instance_variable_set('@profile_user', profile_user)
      likes_count = 5
      profile_user.expects(:likes_count).once.returns(likes_count)
      subject.send(:liked_count).should == likes_count
      # second time should be cached
      subject.send(:liked_count).should == likes_count
    end
  end

  describe '#connection_between_viewer_and_profile_user' do
    before do
      subject.instance_variable_set('@profile_user', profile_user)
    end

    it 'returns the connection between the viewer and the profile user' do
      subject.current_user = viewer
      connection = stub('connection')
      SocialConnection.expects(:find).with(viewer, profile_user).returns(connection)
      subject.send(:connection_between_viewer_and_profile_user).should == connection
      # second time should be cached
      subject.send(:connection_between_viewer_and_profile_user).should == connection
    end

    it 'returns no connection when the viewer is anonymous' do
      SocialConnection.expects(:find).never
      subject.send(:connection_between_viewer_and_profile_user).should be_nil
    end

    it 'returns no connection when the viewer is the profile user' do
      subject.current_user = profile_user
      SocialConnection.expects(:find).never
      subject.send(:connection_between_viewer_and_profile_user).should be_nil
    end
  end

  describe '#results=' do
    it 'sets listing results' do
      subject.current_user = viewer
      listings = stub('listings')
      ListingResults.expects(:new).with(viewer, listings, has_entries(connections: false))
      subject.send(:results=, listings)
    end
  end

  describe '#results' do
    it 'returns listing results' do
      results = stub('results')
      subject.instance_variable_set('@results', results)
      subject.send(:results).should == results
    end
  end
end
