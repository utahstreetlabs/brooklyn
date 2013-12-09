require 'spec_helper'

describe Controllers::NetworkProfileScoped do
  class NetworkProfileScopedController
    def self.before_filter(*args); end

    attr_reader :params

    def initialize
      @params = {}
    end

    include Controllers::NetworkProfileScoped
  end

  subject { NetworkProfileScopedController.new }

  let(:profile) { stub('profile', id: 5555) }

  describe '#load_profile' do
    it 'should load the profile given an id' do
      subject.params[:id] = profile.id
      Rubicon::Profile.expects(:find).with(profile.id).returns(profile)
      subject.send(:load_profile)
    end
  end
end
