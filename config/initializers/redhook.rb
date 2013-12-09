require 'brooklyn/redhook'

conf = Brooklyn::Application.config.signal.connection_weights
Redhook::Connection.connection_weights.keys.each do |key|
  if conf.respond_to?(key)
    Redhook::Connection.connection_weights[key] = conf.send(key).to_f
  end
end

Redhook.configure do |config|
  config.host_count = Brooklyn::Application.config.redhook.host_count
end

if Rails.env.test?
  Brooklyn::Redhook.person = Brooklyn::RedhookTest::Person
  Brooklyn::Redhook.connection = Brooklyn::RedhookTest::Connection
elsif Brooklyn::Application.config.redhook.stub
  Brooklyn::Redhook.person = Brooklyn::RedhookStub::Person
  Brooklyn::Redhook.connection = Brooklyn::RedhookStub::Connection
else
  Brooklyn::Redhook.person = Redhook::Person
  Brooklyn::Redhook.connection = Redhook::Connection
end
