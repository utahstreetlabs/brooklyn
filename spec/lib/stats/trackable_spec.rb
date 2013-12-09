require 'spec_helper'
require 'stats/trackable'

describe Stats::Trackable do
  describe 'a trackable plain old ruby object' do
    class TrackablePoro
      include Stats::Trackable
    end

    subject { TrackablePoro.new }
    let(:hamburgler) { stub_user('hamburgler') }

    describe '#track_usage' do
      let(:props) { {pork: :bacon} }
      it 'calls async_track with the global mixpanel context' do
        Brooklyn::UsageTracker.expects(:async_track).with(:ate_ham, props)
        subject.track_usage(:ate_ham, props)
      end
    end
  end
end
