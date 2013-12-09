require 'spec_helper.rb'

describe Profiles::SyncEach do
  describe "#work" do
    context 'for a person connected to facebook and twitter' do
      let(:person) { stub_person('person', networks: [:facebook, :twitter]) }
      before do
        Person.expects(:find).with(person.id).returns(person)
        person.connected_profiles.each { |p| p.expects(:async_sync) }
      end
      it 'should enqueue sync tasks for all connected profiles' do
        Profiles::SyncEach.work(person.id)
      end
    end
  end
end
