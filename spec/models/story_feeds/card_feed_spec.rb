require 'spec_helper'

describe StoryFeeds::CardFeed do
  subject { StoryFeeds::CardFeed }

  def wrap(stories)
    stories.map {|s| Story.new_from_rising_tide(s) }
  end

  describe '#find_slice' do
    let(:user_id) { 1 }
    let(:options) { {interested_user_id: user_id} }
    let(:raw_feed) { [RisingTide::Story.new] }
    context 'successful feed builds' do
      before { subject.decorated_class.expects(:find_slice).with(options).returns(raw_feed) }

      it 'returns the feed from redis if it exists' do
        subject.find_slice(options).should == wrap(raw_feed)
      end

      context "the user's feed is empty" do
        let(:raw_feed) { [] }
        let(:built_feed) { [RisingTide::Story.new] }

        context 'feed build succeeds' do
          before { subject.decorated_class.expects(:build).with(user_id).returns(built_feed) }

          it 'returns the built feed' do
            Brooklyn::UsageTracker.expects(:async_track).with(:on_demand_feed_build, has_entry(user_id: user_id))
            subject.find_slice(options).should == wrap(built_feed)
          end
        end

        context 'feed build fails' do
          let(:curated_feed) { [RisingTide::Story.new] }
          before do
            subject.decorated_class.expects(:build).with(user_id).raises(Exception)
            subject.decorated_class.expects(:find_slice).with({}).returns(curated_feed)
          end

          it 'raises a CardFeedFetchFailed containing the curated feed' do
            Brooklyn::UsageTracker.expects(:async_track).with(:on_demand_feed_build_failed, user_id: user_id)
            ->{ subject.find_slice(options) }.should raise_error(StoryFeeds::CardFeedFetchFailed.new(wrap(curated_feed), :curated))
          end
        end
      end
    end

    context 'when initial feed fetch raises an exception' do
      before { subject.decorated_class.expects(:find_slice).with(options).raises(Exception) }

      it 'raises a CardFeedFetchFailed exception' do
        ->{ subject.find_slice(options) }.should raise_error(StoryFeeds::CardFeedFetchFailed.new(wrap([]), :empty))
      end
    end
  end
end
