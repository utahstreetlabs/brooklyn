require 'spec_helper'

describe TagStory do
  describe "#local_stub" do
    let(:actor) { stub_user 'William Shatner' }
    let(:tag) { stub 'captain' }
    let(:type) { :tag_liked }
    subject { TagStory.local_stub(tag, type, actor) }
    its(:actor) { should == actor }
    its(:tag) { should == tag }
    its(:type) { should == type }
  end
end
