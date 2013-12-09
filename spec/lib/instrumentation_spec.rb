require 'spec_helper'

describe Brooklyn::Instrumentation do
  class Instrumented
    include Brooklyn::Instrumentation
  end

  subject { Instrumented.new }

  it 'fires an event' do
    name = :happy_hour
    payload = {cocktails: true, mosquitoes: true, rain: false}
    ActiveSupport::Notifications.expects(:instrument).with("#{name}.brooklyn", payload)
    subject.fire_event(name, payload)
  end
end
