require 'spec_helper'

describe ProfileSessionObserver do
  subject { ProfileSessionObserver.instance }

  describe '#after_sign_in' do
    let(:person) { stub_person('Crackity Jonez Person') }
    let(:user) { stub_user('Crackity Jonez', just_registered?: just_registered, person: person) }
    let(:seshun) { stub('session', user: user) }

    context 'for a newly registered user' do
      let(:just_registered) { true }
      before { person.expects(:async_sync_connected_profiles).never }
      it 'does not try to resync' do
        subject.after_sign_in(seshun)
      end
    end

    context 'for a returning user' do
      let(:just_registered) { false }
      before { person.expects(:async_sync_connected_profiles).once }
      it 'resyncs connected profiles' do
        subject.after_sign_in(seshun)
      end
    end
  end
end
