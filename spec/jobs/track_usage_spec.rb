require 'spec_helper'

describe TrackUsage do
  subject { TrackUsage }
  let(:event) { 'ate some ham' }
  let(:user_id) { 1 }
  let(:mixpanel_properties) { {foo: :bar, visitor_id: '12345'} }
  let(:user) { stub_user('hammer', id: user_id, mixpanel_properties: mixpanel_properties) }
  let(:anon_output_params) { {flavor: :greasy, texture: :chunky} }
  let(:anon_input_params) { anon_output_params.stringify_keys }
  let(:input_params) { anon_input_params.merge('user_id' => user_id) }
  let(:output_params) { anon_output_params.merge(mixpanel_properties) }

  describe '#perform' do
    it 'should pass params to mixpanel tracking' do
      Brooklyn::Mixpanel.expects(:track).with(event, anon_output_params)
      subject.perform(event, anon_input_params)
    end

    it 'should look up a user and params to mixpanel tracking' do
      User.expects(:find).with(user_id).returns(user)
      Brooklyn::Mixpanel.expects(:track).with(event, output_params)
      subject.perform(event, input_params)
    end
  end

  class Events::PlayedGuitar < Events::Base
    set_event_name 'played guitar'

    def self.complete_properties(params)
      params.merge(hi: :there)
    end
  end

  describe '#event_name' do
    it 'should return the event_name specified in the class definition' do
      subject.event_name('Events::PlayedGuitar').should == 'played guitar'
    end

    it 'should return event name for a string event' do
      subject.event_name('ham sausages').should == 'ham sausages'
    end
  end

  describe '#complete_event_properties' do
    it 'should return the mp_name specified in the class definition' do
      subject.complete_event_properties('Events::PlayedGuitar', {ok: :then}).should == {hi: :there, ok: :then}

    end
    it 'should pass the params through for a string event name' do
      subject.complete_event_properties('ham socks', {ok: :then}).should == {ok: :then}
    end
  end
end
