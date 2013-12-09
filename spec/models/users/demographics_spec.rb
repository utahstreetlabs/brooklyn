require 'spec_helper'

describe Users::Demographics do
  class DemographicUser < StashingUser
    include Users::Demographics
    attr_reader :person

    def initialize(person)
      @person = person
      super
    end

    def persisted?
      true
    end
  end

  let(:gender) { 'male' }
  let(:birthday) { Date.civil(1983, 7, 5) }
  let(:person) { stub('person') }
  let(:profile) { stub('profile', gender: gender, birthday: birthday) }
  subject { DemographicUser.new(person) }

  it 'should return nil for gender and birthday if no facebook profile' do
    person.expects(:for_network).with(:facebook).returns(nil)
    subject.gender.should == nil
  end

  it 'should call rubicon/facebook to get gender and birthday' do
    [:gender, :birthday].each do |name|
      person.expects(:for_network).with(:facebook).returns(profile).once
      2.times { subject.send(name).should == self.send(name) }
    end
  end

  context 'when gender/birthday are nil' do
    let(:gender) { nil }
    let(:birthday) { nil }
    it 'should coerce gender and birthday correctly' do
      [:gender, :birthday].each do |name|
        person.expects(:for_network).with(:facebook).returns(profile).once
        2.times { subject.send(name).should == nil }
      end
    end
  end

  it 'should query and cache lister, seller, buyer booleans' do
    [:lister?, :seller?, :buyer?].each do |name|
      subject.expects("query_#{name}").returns(true).once
      2.times { subject.send(name).should == true }
    end
  end

  describe 'mark_inviter!' do
  end

  describe 'mark_commenter!' do
    it 'should track tutorial progress for first time commenters' do
      subject.stubs(:commenter?).returns(false)
      subject.expects(:track_tutorial_progress).with(:comment)
      subject.expects(:update_attribute).with(:commenter, true)
      subject.mark_commenter!
    end

    it 'should not track tutorial progress for an existing commenter' do
      subject.stubs(:commenter?).returns(true)
      subject.expects(:track_tutorial_progress).never
      subject.expects(:update_attribute).never
      subject.mark_commenter!
    end
  end

  describe 'mark_inviter!' do
    it 'should track tutorial progress for first time inviters' do
      subject.stubs(:inviter?).returns(false)
      subject.expects(:track_tutorial_progress).with(:invite)
      subject.expects(:update_attribute).with(:inviter, true)
      subject.mark_inviter!
    end

    it 'should not track tutorial progress for an existing inviter' do
      subject.stubs(:inviter?).returns(true)
      subject.expects(:track_tutorial_progress).never
      subject.expects(:update_attribute).never
      subject.mark_inviter!
    end
  end
end
