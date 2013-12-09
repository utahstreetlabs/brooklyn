require 'spec_helper'

describe Controllers::ListingsFeed do
  class ListingsFeedController
    def self.before_filter(*args); end

    attr_reader :params, :current_user

    def initialize(current_user)
      @params = {}
      @current_user = current_user
    end

    def logged_in?
      true
    end

    def logger
      Rails.logger
    end

    def self.helper_method(*args)
    end

    include Controllers::ListingsFeed
  end

  let(:viewer) { stub_user 'Charlotte Gainsbourg', tag_likes_for: [] }
  let(:stories) { [] }
  let(:feed) { mock('feed') }

  subject { ListingsFeedController.new(viewer) }

  describe '#load_listings_feed' do
    let(:args) { {limit: product_cards_limit, user_feed: true} }
    before do
      CardFeed.expects(:new).with(viewer, args).returns(feed)
    end

    context 'by default' do
      it "should load and memoize a listings feed with user_feed set to true" do
        feed_should_load_correctly
      end
    end

    context 'when everything feed is requested' do
      let(:args) { {limit: product_cards_limit, user_feed: false} }
      before { subject.params[:feed] = 'everything' }

      it "should load and memoize a listings feed with user_feed set to false" do
        feed_should_load_correctly
      end
    end

    context 'when network feed is requested' do
      before { subject.params[:feed] = 'network' }

      it "should load and memoize a listings feed with user_feed set to true" do
        feed_should_load_correctly
      end
    end

    def feed_should_load_correctly
      actual = subject.send(:load_listings_feed)
      actual.should == feed
      subject.send(:load_listings_feed).should == feed
    end
  end

  def product_cards_limit
    Brooklyn::Application.config.feed.defaults.limit
  end
end
