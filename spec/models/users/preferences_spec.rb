require 'spec_helper'

describe Users::Preferences do
  class PreferencesUser
    include Users::Preferences
  end

  before { PreferencesUser.stubs(:logger).returns(stub_everything) }

  subject do
    u = PreferencesUser.new
    u.stubs(:logger).returns(stub_everything)
    u
  end

  let(:preferences) { stub('preferences') }
  before { subject.stubs(:preferences).returns(preferences) }

  describe ".save_email_prefs" do
    it "saves an opt-in" do
      preferences.expects(:save_email_opt_outs).with('follow_me' => true).returns({})
      subject.save_email_prefs('follow_me' => '0').should == true
    end

    it "saves an opt-out" do
      preferences.expects(:save_email_opt_outs).with('follow_me' => false).returns({})
      subject.save_email_prefs('follow_me' => '1').should == true
    end

    it "returns false when there is an error saving the prefs" do
      preferences.expects(:save_email_opt_outs).with('follow_me' => true).returns(nil)
      subject.save_email_prefs('follow_me' => '0').should == false
    end
  end

  describe ".save_features_disabled_prefs" do
    it "saves an enabled feature" do
      preferences.expects(:save_features_disabled).with('request_timeline_facebook' => true).returns({})
      subject.save_features_disabled_prefs('request_timeline_facebook' => '0').should == true
    end

    it "saves an disabled feature" do
      preferences.expects(:save_features_disabled).with('request_timeline_facebook' => false).returns({})
      subject.save_features_disabled_prefs('request_timeline_facebook' => '1').should == true
    end

    it "returns false when there is an error saving the prefs" do
      preferences.expects(:save_features_disabled).with('request_timeline_facebook' => true).returns(nil)
      subject.save_features_disabled_prefs('request_timeline_facebook' => '0').should == false
    end
  end

  describe ".allow_feature?" do
    let(:feature) { "request_timeline_facebook" }

    it "returns true when feature not disabled" do
      preferences.stubs(:features_disabled).returns([])
      subject.allow_feature?(:request_timeline_facebook).should be_true
    end

    it "returns false when feature is disabled" do
      preferences.stubs(:features_disabled).returns(['request_timeline_facebook'])
      subject.allow_feature?(:request_timeline_facebook).should be_false
    end
  end
end
