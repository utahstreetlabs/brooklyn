require 'spec_helper'

describe Users::AutoShareable do
  class AutoSharingUser
    include Users::AutoShareable
    attr_reader :preferences, :person, :logger

    def initialize(preferences, person)
      @preferences = preferences
      @person = person
      @logger = Rails.logger
    end
  end

  subject { AutoSharingUser.new(stub('preferences', never_autoshare: false), stub_person('person')) }
  let(:network) { :twitter }

  describe "#allow_autoshare?" do
    let(:event) { :listing_activated }

    it "allows autosharing for a network" do
      subject.preferences.expects(:allow_autoshare?).with(network, event).returns(true)
      subject.allow_autoshare?(event, network).should be_true
    end

    it "disallows autosharing for a network" do
      subject.preferences.expects(:allow_autoshare?).with(network, event).returns(false)
      subject.allow_autoshare?(event, network).should be_false
    end
  end

  def allow_autoshare?(event, network)
    prefs = options[:preferences] || preferences
    prefs.allow_autoshare?(network, event)
  end


  describe "#autoshare" do
    it "autoshares to connected networks" do
      event = :something
      arg1 = :arg1
      arg2 = :arg2
      subject.person.connected_networks.each do |network|
        subject.expects(:allow_autoshare?).with(event, network).returns(true)
        subject.person.expects(:share_something).with(network, arg1, arg2)
      end
      subject.autoshare(event, arg1, arg2)
    end
  end

  describe "#save_autoshare_prefs" do
    it "saves an opt-in" do
      subject.preferences.expects(:save_autoshare_opt_ins).with(network, ['listing_activated']).returns({})
      subject.save_autoshare_prefs(network,'listing_activated' => '1').should be_true
    end

    it "saves an opt-out" do
      subject.preferences.expects(:save_autoshare_opt_ins).with(network, []).returns({})
      subject.save_autoshare_prefs(network, 'listing_actiavted' => '0').should be_true
    end

    it "returns false when there is an error saving the prefs" do
      subject.preferences.expects(:save_autoshare_opt_ins).with(network, ['listing_activated']).returns(nil)
      subject.save_autoshare_prefs(network,'listing_activated' => '1').should be_false
    end
  end
end
