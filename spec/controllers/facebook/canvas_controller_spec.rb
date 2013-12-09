require 'spec_helper'

describe Facebook::CanvasController do
  describe "redirect_for_referer" do
    context "when redirected from a notification referencing a listing" do
      let(:referer) { 'https://apps.facebook.com/copious/listings/wat' }

      it "should redirect to the listing" do
        @request.env['HTTP_REFERER'] = referer
        subject.redirect_for(referer).should == listing_url('wat')
      end
    end

    context "when redirected from a notification referencing a user profile" do
      let(:referer) { 'https://apps.facebook.com/copious/profiles/wat' }

      it "should redirect to the user profile" do
        @request.env['HTTP_REFERER'] = referer
        subject.redirect_for(referer).should == public_profile_url('wat')
      end
    end

    context "when not redirected from a notification" do
      it "should reidrect to the root" do
        subject.redirect_for('/').should == root_url
      end
    end
  end
end
