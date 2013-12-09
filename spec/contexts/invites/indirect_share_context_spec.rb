require 'spec_helper'
require 'invites/indirect_share_context'

describe Invites::IndirectShareContext do
  let(:view_context) { stub('view-context', smart_number_to_currency: '$100') }

  describe '#share_dialog_url' do
    let(:user) { stub_user('Caprica Six', untargeted_invite_code: 'hams', profile_photo_url: '//example.com') }

    it "generates a share dialog url for twitter" do
      Invites::IndirectShareContext.share_dialog_url(:twitter, user, view_context).should ==
        "http://twitter.com/share?text=I'm%20on%20Copious.%20Join%20me%20and%20get%20$100!&related=shopcopious&url=http%3A%2F%2Fexample.com%2Finvites%2Fhams&counturl=http%3A%2F%2Fexample.com%2Finvites%2Fhams"
    end

    it "generates a share dialog url for facebook" do
      desc = URI.escape(I18n.translate('contexts.invites.indirect_share.desc', name: user.firstname))
      Invites::IndirectShareContext.share_dialog_url(:facebook, user, view_context).should ==
        "http://www.facebook.com/dialog/feed?app_id=152878758105839&link=http%3A%2F%2Fexample.com%2Finvites%2Fhams&name=I'm%20on%20Copious.%20Join%20me%20and%20get%20$100!&picture=http%3A%2F%2Fexample.com&redirect_uri=http%3A%2F%2Fexample.com%2Fcallbacks%2Fshared&display=popup&description=Copious%20is%20a%20marketplace%20where%20you%20can%20find%20more%20of%20what%20you%20love,%20no%20matter%20what%20you're%20into.%20What%20you%20see%20is%20powered%20by%20your%20interests%20and%20friends,%20so%20everything%20is%20curated%20for%20you,%20by%20you.%20Join%20me.&ref=inviteis2&actions=[{\"name\":\"Join Caprica\",\"link\":\"http%3A%2F%2Fexample.com%2Finvites%2Fhams\"}]"

      Invites::IndirectShareContext.share_dialog_url(:facebook, user, view_context, fb_ref: 'plaster').should ==
        "http://www.facebook.com/dialog/feed?app_id=152878758105839&link=http%3A%2F%2Fexample.com%2Finvites%2Fhams&name=I'm%20on%20Copious.%20Join%20me%20and%20get%20$100!&picture=http%3A%2F%2Fexample.com&redirect_uri=http%3A%2F%2Fexample.com%2Fcallbacks%2Fshared&display=popup&description=Copious%20is%20a%20marketplace%20where%20you%20can%20find%20more%20of%20what%20you%20love,%20no%20matter%20what%20you're%20into.%20What%20you%20see%20is%20powered%20by%20your%20interests%20and%20friends,%20so%20everything%20is%20curated%20for%20you,%20by%20you.%20Join%20me.&ref=plaster&actions=[{\"name\":\"Join Caprica\",\"link\":\"http%3A%2F%2Fexample.com%2Finvites%2Fhams\"}]"

    end
  end
end
