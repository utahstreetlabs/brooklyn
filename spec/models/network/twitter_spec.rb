require 'spec_helper'

describe Network::Twitter do
  let(:config) do
    OpenStruct.new(twitter: OpenStruct.new(corporate: 'shopcopious'))
  end

  before do
    Network.stubs(:config).returns(config)
  end

  describe '#message_options!' do
    let(:message) { :listing_liked }
    let(:params) { {} }
    let(:options) { {} }
    let(:message_options) { {text: 'TEXT'} }

    it "adds copious param" do
      message_options.each_pair do |key, str|
        Network::Twitter.expects(:message_string).with(message, key, has_key(:copious), options).returns(str)
      end
      Network::Twitter.message_options!(message, params, options).should == message_options
    end

    it "adds other_user_username param when other user profile is provided" do
      options[:other_user_profile] = stub('other-user-profile', username: 'Other User')
      message_options.each_pair do |key, str|
        Network::Twitter.expects(:message_string).with(message, key, has_key(:other_user_username), options).
          returns(str)
      end
      Network::Twitter.message_options!(message, params, options).should == message_options
    end
  end

  describe '#message_string_scope' do
    let(:message) { :listing_liked }
    let(:options) { {} }

    it "chooses the on network scope when other user profile not provided" do
      options[:other_user_profile] = stub('other-user-profile', username: 'Other User')
      Network::Twitter.message_string_scope(message, options).should include(:other_user_on_network)
    end

    it "chooses the off network scope when other user profile is not provided" do
      Network::Twitter.message_string_scope(message, options).should include(:other_user_off_network)
    end
  end

  describe '#fixup_share_message_options' do
    it "truncates the variable part and leaves the fixed part alone" do
      other_user = stub_network_profile('glenn-frey', username: 'glennfrey')
      params = {
        listing: 'Tequila Sunrise by EAGLES',
        comment: "Oh, and it's a hollow feelin' when it comes down to dealin' friends, it never ends",
        link: 'http://t.co/deadbeef'
      }
      original_options = {other_user_profile: other_user}
      sharing_options = {
        text: "%s about %s by @%s on @%s %s" % [params[:comment], params[:listing], other_user.username,
          Network::Twitter.copious_username, params[:link]]
      }
      fixed_up_options = Network::Twitter.fixup_share_message_options(params, original_options, sharing_options)
      fixed_up_options[:text].should =~ /\.\.\. by @glenn-frey on @#{Network::Twitter.copious_username} #{params[:link]}/
    end
  end
end
