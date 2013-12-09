# Normally we'd use a test driver to gate access to an external system, but the Redis API is so flat and easy to stub
# that there's not really any reason to do anything more complicated.
RSpec.configure do |config|
  config.before do
    redis = stub_everything(redis)
    # stub everything that expects to have a redis handle (as per the application initializer)
    Redis.stubs(:current).returns(redis)
    User.stubs(:redis).returns(redis)
    User.any_instance.stubs(:top_message).returns({}) # XXX: why doesn't stubbing User.redis work here?
    Resque.redis = redis
  end
end
