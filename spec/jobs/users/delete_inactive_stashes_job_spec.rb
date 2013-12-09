require 'spec_helper.rb'

describe Users::DeleteInactiveStashesJob do
  it "deletes inactive stashes" do
    seconds = 100
    num_deleted = 23
    User.expects(:delete_inactive_stashes!).with(seconds).returns(num_deleted)
    Users::DeleteInactiveStashesJob.perform(seconds).should == num_deleted
  end
end
