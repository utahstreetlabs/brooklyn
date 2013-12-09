require 'spec_helper'
require 'listings/indirect_share_context'

describe Listings::IndirectShareContext do
  describe '#share_dialog_url' do
    let(:listing) { stub_listing('Unicorn Kidneys (24-pack)', seller: stub_user('Bjork')) }
    let(:photo) { listing.photos.first }
    let(:view_context) { stub('view-context', number_to_currency: '$100.00') }

    it "generates a share dialog url for twitter" do
      Person.stubs(:sharing_options!).returns({text: "Checking out Unicorn Kidneys (24-pack) by @bjork-person-twitter-profile on @shopcopious"})
      Listings::IndirectShareContext.share_dialog_url(:twitter, listing, photo, view_context).should ==
        "http://twitter.com/share?text=Checking%20out%20Unicorn%20Kidneys%20(24-pack)%20by%20%40bjork-person-twitter-profile%20on%20%40shopcopious&related=shopcopious,bjork-person-twitter-profile&url=http%3A%2F%2Fexample.com%2Flistings%2Funicorn-kidneys-24-pack&counturl=http%3A%2F%2Fexample.com%2Flistings%2Funicorn-kidneys-24-pack"
    end

    it "generates a share dialog url for facebook" do
      Person.stubs(:sharing_options!).returns({})
      Listings::IndirectShareContext.share_dialog_url(:facebook, listing, photo, view_context).should ==
        "http://www.facebook.com/dialog/feed?app_id=152878758105839&link=http%3A%2F%2Fexample.com%2Flistings%2Funicorn-kidneys-24-pack&name=Unicorn%20Kidneys%20(24-pack)&picture=&redirect_uri=http%3A%2F%2Fexample.com%2Fcallbacks%2Fshared&display=popup"
    end

    it "generates a share dialog url for tumblr" do
      Person.stubs(:sharing_options!).returns({})
      Listings::IndirectShareContext.share_dialog_url(:tumblr, listing, photo, view_context).should ==
        "http://www.tumblr.com/share/photo?source=&caption=Unicorn%20Kidneys%20(24-pack)&clickthru=http%3A%2F%2Fexample.com%2Flistings%2Funicorn-kidneys-24-pack"
    end

    it "generates a share dialog url for pinterest" do
      Person.stubs(:sharing_options!).returns({})
      Listings::IndirectShareContext.share_dialog_url(:pinterest, listing, photo, view_context).should ==
        "http://pinterest.com/pin/create/button/?url=http%3A%2F%2Fexample.com%2Flistings%2Funicorn-kidneys-24-pack&media=&description=Unicorn%20Kidneys%20(24-pack)"
    end
  end
end
