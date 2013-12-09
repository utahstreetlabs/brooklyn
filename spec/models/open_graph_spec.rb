require 'spec_helper'

describe OpenGraph do
  class TestOpenGraph
    include OpenGraph
  end

  subject { TestOpenGraph }

  describe '#open_graph_object_props' do
    let(:action) { :post }
    let(:object_url) { '/url/to/listing' }
    let(:object_type) { 'copious:listing' }
    let(:user) { stub_user('Skunk Baxter') }
    let(:profile) { stub('profile', uid: 5555, name: 'Skunk Baxter') }
    let(:basic_options) { { namespace: :copious, action: action, object: object_type, link: object_url, params: {}} }
    let(:ref_params) { {ref: "#{object_type}:#{action}"} }

    it 'populates posting options' do
      expected_props = basic_options
      expected_props[:params].merge!(ref_params)
      subject.open_graph_object_props(action, object_type, object_url, params: {}).should == expected_props
    end

    it 'populates images' do
      images = [
        'http://d24w6bsrhbeh9d.cloudfront.net/photo/4805367_700b_v1.jpg',
        'http://d24w6bsrhbeh9d.cloudfront.net/photo/4798202_700b.jpg',
        'http://d24w6bsrhbeh9d.cloudfront.net/photo/4803194_700b.jpg'
      ]
      ug_image_opts = images.each_with_index.reduce({}) do |m, (image, i)|
        m["image[#{i}][url]"] = image
        m["image[#{i}][user_generated]"] = true
        m
      end
      subject.open_graph_object_props(action, object_type, object_url, user_generated_images: images).should ==
        basic_options.merge(params: ug_image_opts.merge(ref_params))
    end

    it 'populates posting options when given valid target' do
      User.expects(:find).with(user.id).returns(user)
      user.person.expects(:for_network).returns(profile)
      opts = subject.open_graph_object_props(action, object_type, object_url, to: user.id)
      opts[:tags].should == profile.uid
    end

    it 'does not populate tags when no profile exists' do
      User.expects(:find).with(user.id).returns(user)
      user.person.expects(:for_network).returns(nil)
      opts = subject.open_graph_object_props(action, object_type, object_url, to: user.id)
      opts[:tags].should be_nil
    end

    it 'populates message for valid profile and target' do
      User.expects(:find).with(user.id).returns(user)
      user.person.expects(:for_network).returns(profile)
      opts = subject.open_graph_object_props(action, object_type, object_url, to: user.id, message: "This is a test")
      opts[:tags].should_not be_nil
      opts[:message].should_not be_nil
    end
  end
end
