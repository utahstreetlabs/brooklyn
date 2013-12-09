require 'spec_helper'

describe Network::Facebook do
  subject { Network::Facebook }

  let(:config) do
    OpenStruct.new(
      facebook: OpenStruct.new(app_id: 'deadbeef', app_secret: 'cafebebe', access_token: 'phatpipe',
        url: 'http://facebook.com/', timeline_autoshare: [:listing_activated]))
  end

  describe "update_preferences" do
    let(:user) { stub('user') }
    let(:preferences) { stub('preferences') }
    let(:options) { {:scope => "publish_actions"} }
    let(:publish_permission) { true }

    before do
      user.stubs(:preferences).returns(preferences)
      subject.expects(:has_permission?).with(options[:scope], :publish_actions).returns(publish_permission)
    end

    context "when :publish_actions is set" do
      it "saves autoshare preferences" do
        subject.expects(:autoshare_events).returns([:listing_activated])
        user.expects(:allow_feature?).returns(true)
        user.expects(:save_features_disabled_prefs)
        user.expects(:save_autoshare_prefs)
        preferences.expects(:save_never_autoshare).with(false)
        subject.update_preferences(user, options)
      end
    end

    context "when :publish_actions is not set" do
      let(:publish_permission) { false }

      it "doesn't save autoshare preferences when called" do
        user.expects(:save_autoshare_prefs).never
        preferences.expects(:save_never_autoshare).never
        subject.update_preferences(user, options)
      end
    end
  end

  describe "auth_failure_message" do
    let(:options) { {:scope => "publish_actions"} }

    it "returns the facebook_timeline message" do
      subject.auth_failure_message(options).should == :facebook_timeline
    end
  end

  describe "auth_failure_lambda" do
    let(:options) { {:scope => "publish_actions"} }

    it "returns a proc when publish_actions permission is present" do
      subject.auth_failure_lambda(options).is_a?(Proc).should be_true
    end

    it "returns nil when no conditions are met" do
      subject.auth_failure_lambda({}).is_a?(Proc).should be_false
    end

    context "when calling the lambda" do
      let(:user) { stub('user') }
      let(:preferences) { stub('preferences') }

      before do
        user.stubs(:preferences).returns(preferences)
      end

      it "saves facebook timeline feature preferences when called" do
        lambda = subject.auth_failure_lambda(options)
        lambda.is_a?(Proc).should be_true
        user.expects(:allow_feature?).returns(true)
        user.expects(:save_features_disabled_prefs)
        lambda.call(user)
      end
    end
  end

  describe "allow_feed_autoshare?" do
    it "returns true when an event is not posted to the timeline" do
      subject.allow_feed_autoshare?(:foobar).should be_true
    end

    it "returns false when an event is posted to the timeline" do
      subject.allow_feed_autoshare?(:listing_activated).should be_false
    end
  end

  describe '#user_generated_images' do
    let(:listing) { stub('listing', photos: photos) }
    let(:count) { 3 }
    let(:version) { :large }
    # minimum 480px comes from the facebook documentation
    # http://developers.facebook.com/docs/opengraph/usergeneratedphotos/
    let(:photos) do
      [ stub_image('just right', [480, 480]),
        stub_image('too short', [450, 500]),
        stub_image('perfect', [500, 500]),
        stub_image('too narrow', [500, 450]),
        stub_image('optimal', [500, 580]),
        stub_image('ideal', [500, 580])]
    end

    it 'return the version urls of the first three appropriately sized images' do
      subject.user_generated_images(listing, count).should ==
        ['just right', 'perfect', 'optimal']
    end

    def stub_image(name, dimensions)
      stub(name, image_dimensions: dimensions, file: stub("#{name} file", url: name))
    end

  end
end
