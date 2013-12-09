require 'spec_helper'

describe ProfilePhotoUploader do
  let(:facebook_profile) { stub('fb profile', fbid: 1234, typed_photo_url: 'http://img.com/img?type=large') }
  let(:twitter_profile) { stub('tw profile', username: 'devopsborat') }
  let(:person) { stub('person' )}
  before do
    person.stubs(:for_network).with(:facebook).returns(facebook_profile)
    person.stubs(:for_network).with(:twitter).returns(twitter_profile)
  end
  let(:user) { stub('user', id: 1, class: User.class, person: person) }

  subject { ProfilePhotoUploader.new(user, :profile_photo) }
  context "when downloading from facebook" do

    it "ignores default profile images" do
      Typhoeus::Request.expects(:head).with(facebook_profile.typed_photo_url).returns(
        stub(code: 301, headers_hash: { location: 'https://img.com/static-ak/img' }, success?: false)
      )
      subject.expects(:download!).never
      subject.download_from_network!(:facebook)
    end

    it "follows valid redirect and downloads" do
      redirect_url = 'http://img.com/something.img'
      Typhoeus::Request.expects(:head).with(facebook_profile.typed_photo_url).returns(
        stub(code: 301, headers_hash: { location: redirect_url }, success?: false)
      )
      Typhoeus::Request.expects(:head).with(redirect_url).returns(
        stub(success?: true)
      )
      subject.expects(:download!).with(redirect_url).returns(nil)
      subject.download_from_network!(:facebook)
    end
  end

  context "with downloading from twitter" do
    it "skips checking extensions and downloads" do
      url = 'http://img.com/something'
      Typhoeus::Request.expects(:head).with(url).returns(
        stub(success?: true)
      )
      Twitter.expects(:profile_image).returns(url)
      subject.expects(:download!).with(url).returns(nil)
      subject.download_from_network!(:twitter)
    end

    it "fetches the big photo when the original doesn't exist" do
      url_original = 'http://img.com/original'
      url_bigger = 'http://img.com/bigger'
      Typhoeus::Request.expects(:head).with(url_original).returns(
        stub(code: 404, success?: false, timed_out?: false)
      )
      Typhoeus::Request.expects(:head).with(url_bigger).returns(
        stub(success?: true)
      )
      Twitter.expects(:profile_image).with(twitter_profile.username, size: :original).returns(url_original)
      Twitter.expects(:profile_image).with(twitter_profile.username, size: :bigger).returns(url_bigger)
      subject.expects(:download!).with(url_bigger).returns(nil)
      subject.download_from_network!(:twitter)
    end
  end

  context "when requesting a url" do
    context "for a user with no profile photo" do
      it "returns a default url in the right format" do
        subject.url(:px_30x30).should match(
          /[\w]*#{ProfilePhotoUploader.default_file_path}\/px_30x30_#{ProfilePhotoUploader.default_file_name}/)
      end
    end
  end
end
