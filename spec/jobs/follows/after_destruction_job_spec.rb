require 'spec_helper'

describe Follows::AfterDestructionJob do
  let(:follower) { stub_user 'Lisbeth Salander', id: 123, person_id: 123 }
  let(:followee) { stub_user 'Mikael Blomkvist', id: 456, person_id: 456 }

  subject { Follows::AfterDestructionJob }

  describe '#destroy_connection' do
    it 'enqueues the job' do
      Brooklyn::Redhook.expects(:async_destroy_connection).with(follower.person_id, followee.person_id, :usl_follower)
      subject.destroy_connection(follower, followee)
    end
  end
end
