require 'spec_helper'

describe Controllers::Instrumentation do
  class InstrumentedController
    include Controllers::Instrumentation
  end

  let(:action_name) { 'index' }
  let(:request) { mock('request') }
  let(:current_user) { mock('current_user') }
  let(:params) { {'foo' => 'bar'} }

  subject do
    c = InstrumentedController.new
    c.stubs(:action_name).returns(action_name)
    c.stubs(:request).returns(mock)
    c.stubs(:current_user).returns(mock)
    c.stubs(:params).returns(params)
    c.stubs(:instance_variable_get).with('@baz').returns('quux')
    c
  end

  describe '#append_info_to_payload' do
    let(:payload) { {} }
    let(:param) { :foo }

    before do
      InstrumentedController.instance_variable_set("@payload_customizations",
        [Controllers::Instrumentation::Params.new(params: [:foo]),
         Controllers::Instrumentation::Vars.new(variables: [:baz])])
    end

    it 'applies only a skip' do
      InstrumentedController.payload_customizations << Controllers::Instrumentation::Skip.new
      subject.append_info_to_payload(payload)
      payload.should include(skip: true)
      payload.should_not include(foo: 'bar')
      payload.should_not include(baz: 'quux')
    end

    it 'applies non-skips' do
      subject.append_info_to_payload(payload)
      payload.should_not include(skip: true)
      payload.should include(foo: 'bar')
      payload.should include(baz: 'quux')
    end
  end
end
