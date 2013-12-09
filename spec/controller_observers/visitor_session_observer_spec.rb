require 'spec_helper'

describe VisitorSessionObserver do
  describe "#after_sign_in" do
    let(:user) { stub_user 'Adam Duritz', visitor_id: user_visitor_id }
    let(:session) { stub(user: user) }
    let(:controller) { stub('controller', visitor_identity: cookie_visitor_id) }
    let(:sess) { Session.new }

    before do
      ControllerObserverBase.controller = controller
    end

    context "no current user visitor_id" do
      let(:user_visitor_id) { nil }
      let(:cookie_visitor_id) { 'abcdefg' }

      it "sets the visitor_id on the user if there isn't one" do
        user.expects(:visitor_id=).with(cookie_visitor_id)
        user.expects(:save).returns(true)
        sess.sign_in(user)
      end
    end

    context "existing user visitor_id" do
      let(:user_visitor_id) { 'tuvwxyz' }

      context "and no visitor_identity cookie" do
        let(:cookie_visitor_id) { nil }

        it "doesn't update the visitor_id, but sets the cookie" do
          user.expects(:visitor_id=).never
          controller.expects(:set_visitor_id_cookie).with(user_visitor_id)
          sess.sign_in(user)
        end
      end

      context "and a mismatched visitor_identity cookie" do
        let(:cookie_visitor_id) { 'abcdef' }

        it "doesn't update the visitor_id, but sets the cookie" do
          user.expects(:visitor_id=).never
          controller.expects(:set_visitor_id_cookie).with(user_visitor_id)
          sess.sign_in(user)
        end
      end

      context "and a matching visitor_identity cookie" do
        let(:cookie_visitor_id) { user_visitor_id }

        it "doesn't update the visitor_id, but sets the cookie" do
          user.expects(:visitor_id=).never
          controller.expects(:set_visitor_id_cookie).with(user_visitor_id)
          sess.sign_in(user)
        end
      end
    end
  end
end
