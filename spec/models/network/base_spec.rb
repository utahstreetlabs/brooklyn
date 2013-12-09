require 'spec_helper'

describe Network::Base do
  class Network::Friendster < Network::Base
    def self.symbol
      :friendster
    end
  end

  class Network::Orkut < Network::Base
    def self.symbol
      :orkut
    end
  end

  class Network::Tribe < Network::Base
    def self.symbol
      :tribe
    end
  end

  let(:config) do
    OpenStruct.new(
      friendster: OpenStruct.new(app_id: 'deadbeef', app_secret: 'cafebebe', access_token: 'phatpipe',
        url: 'http://friendster.com/'),
      orkut: OpenStruct.new(permissions: OpenStruct.new(permissions: OpenStruct.new(required: [:one, :two])),
        autoshare: [:foo, :bar]),
      tribe: OpenStruct.new())
  end

  before do
    Network.stubs(:known).returns([:friendster, :orkut])
    Network.stubs(:active).returns([:orkut])
    Network.stubs(:registerable).returns([:orkut])
    Network.stubs(:config).returns(config)
  end

  describe '#config' do
    it "returns the network config" do
      Network::Friendster.config.should == Network.config.friendster
    end
  end

  describe '#app_id' do
    it "returns the app id" do
      Network::Friendster.app_id.should == Network.config.friendster.app_id
    end
  end

  describe '#app_secret' do
    it "returns the app secret" do
      Network::Friendster.app_secret.should == Network.config.friendster.app_secret
    end
  end

  describe '#access_token' do
    it "returns the access token when the network has one" do
      Network::Friendster.access_token.should == Network.config.friendster.access_token
    end

    it "returns nil when the network does not have an access token" do
      Network::Tribe.access_token.should be_nil
    end
  end

  describe '#auth_callback_path' do
    it "returns path for a known network" do
      Network::Facebook.auth_callback_path.should_not be_nil
    end

    it "raises exception for an unknown network" do
      expect { Network::Path.auth_callback_path }.to raise_exception
    end
  end

  describe '#known?' do
    it "returns true for a known network" do
      Network::Friendster.known?.should be_true
    end

    it "returns false for an unknown network" do
      Network::Tribe.known?.should be_false
    end
  end

  describe '#active?' do
    it "returns true for an active network" do
      Network::Orkut.active?.should be_true
    end

    it "returns false for an inactive network" do
      Network::Tribe.active?.should be_false
    end
  end

  describe '#registerable?' do
    it "returns true for a registerable network" do
      Network::Orkut.registerable?.should be_true
    end

    it "returns false for an unregisterable network" do
      Network::Tribe.registerable?.should be_false
    end
  end

  describe "#allow_feed_autoshare?" do
    it "returns true" do
      Network::Orkut.allow_feed_autoshare?(:listing_activated).should be_true
    end
  end

  describe '#required_permissions' do
    it "returns required permissions for a network with defined permissions" do
      Network::Orkut.required_permissions.should == Network.config.orkut.permissions.required
    end

    it "returns an empty array for a network without defined permissions" do
      Network::Friendster.required_permissions.should == []
    end
  end

  describe '#home_url' do
    it "returns the network's home page url" do
      Network::Friendster.home_url.should == Network.config.friendster.url
    end
  end

  describe '#autoshare_events' do
    it "returns autoshare events for a network with defined ones" do
      Network::Orkut.autoshare_events.should == Network.config.orkut.autoshare
    end

    it "returns an empty array for a network without defined autoshare events" do
      Network::Friendster.autoshare_events.should == []
    end
  end

  describe '#message_options!' do
    let(:message) { :foo }
    let(:params) { {} }
    let(:options) { {} }

    it "includes translated strings" do
      text_string = 'TEXT'
      Network::Friendster.stubs(:message_string_keys).returns([:text, :link])
      Network::Friendster.stubs(:message_string).with(message, :text, params, options).returns(text_string)
      Network::Friendster.stubs(:message_string).with(message, :link, params, options).returns('')
      message_options = Network::Friendster.message_options!(message, params, options)
      message_options.should == {text: text_string}
    end

    it "includes message options" do
      bar_value = :bar
      Network::Friendster.stubs(:message_option_names).returns([:bar, :baz])
      Network::Friendster.stubs(:message_option).with(message, :bar).returns(bar_value)
      Network::Friendster.stubs(:message_option).with(message, :baz).returns('')
      message_options = Network::Friendster.message_options!(message, params, options)
      message_options.should == {bar: bar_value}
    end
  end

  describe '#message_string' do
    it "returns a translated message string" do
      message = :foo
      key = :bar
      scope = []
      translated_string = 'foobar'
      Network::Friendster.expects(:message_string_scope).with(message, {}).returns(scope)
      I18n.expects(:translate).with(key, has_entries(scope: scope, default: '')).returns(translated_string)
      Network::Friendster.message_string(message, key).should == translated_string
    end
  end

  describe '#message_option' do
    let(:message) { :foo }
    let(:name) { :bar }
    let(:message_config) { mock('message-config') }

    before do
      Network::Friendster.config.stubs(message).returns(message_config)
    end

    it "returns the message option when one is configured" do
      config_value = :foobar
      message_config.stubs(name => config_value)
      Network::Friendster.message_option(message, name).should == config_value
    end

    it "returns nil when the message option is not configured" do
      config_value = nil
      message_config.stubs(name => config_value)
      Network::Friendster.message_option(message, name).should be_nil
    end
  end

  describe "has_permission?" do
    let(:scope) { "foo,bar,  baz, quux" }

    context "when there is no scope" do
      it "should return false" do
        Network::Friendster.has_permission?(nil, :foobar).should be_false
      end
    end

    context "when permission does not exist in scope" do
      it "should return false" do
        Network::Friendster.has_permission?(scope, :foobar).should be_false
      end
    end

    context "when permission does exist in scope" do
      it "should return true" do
        Network::Friendster.has_permission?(scope, :baz).should be_true
      end
    end
  end

  describe "default_scope?" do
    before do
      Network::Friendster.stubs(:scope).returns("foo,bar,baz,quux")
    end

    it "should return false when there is no scope" do
      Network::Friendster.default_scope?(nil).should be_false
    end

    it "should return false when not the default scope" do
      Network::Friendster.default_scope?("foobar").should be_false
    end

    it "should return true when it is the default scope" do
      Network::Friendster.default_scope?("foo,bar,baz,quux").should be_true
    end
  end
end
