module ActivityHelpers
  RSpec::Matchers.define :have_activities do |count|
    match do |page|
      page.all('.activity').size.should == count
    end
    failure_message_for_should do |actual|
      "expected #{count} activities, not #{actual}"
    end
  end
end

RSpec.configure do |config|
  config.include ActivityHelpers
end
