require 'rspec/core'
require 'rspec/matchers'

module Brooklyn
  module Matchers
    RSpec::Matchers.define :be_jsend_unauthorized do
      match do |response|
        response.jsend_code.should == 401
      end
      failure_message_for_should do |response|
        "Response should be JSend unauthorized"
      end
      failure_message_for_should_not do |response|
        "Response should not be JSend unauthorized"
      end
    end
  end
end
