require 'spec_helper'

describe Profiles::FollowController do
  # XXX: rewrite using factories

  shared_context 'profile follower and followee lists' do
    let (:user) { act_as_stub_user }
    let (:user_slug) { '1' }
    let (:followers) { [] }
    before { User.expects(:find_by_slug!).with(user_slug).returns(user) }
  end

  context "follow, unfollow, block, unblock, share_follow" do
    let (:user) { stub_everything('followee') }
    let (:user_slug) { 'hamdogs' }

    context "#follow" do
      it_behaves_like 'secured against anonymous users' do
        before { click_follow_link }
      end

      context "by a user" do
        include_context "for a logged-in user"

        let (:follow) { stub('follow') }

        before do
          User.expects(:find_by_slug!).with(user_slug).returns(user)
          follow.stubs(:refollow?).returns(false)
        end

        context "when a follow is created" do
          before do
            subject.current_user.expects(:follow!).once.with(user).returns(follow)
          end
          
          it "succeeds" do
            follow.stubs(:refollow?).returns(false)
            click_follow_link
            response.should redirect_to(public_profile_path(user))
          end
          
          it "returns follow info" do
            follow.stubs(:refollow?).returns(false)
            controller.current_user.expects(:following?).with(user).returns(true)
            user.expects(:followers).returns([stub_everything('follower')])
            click_follow_link(true)
            response.jsend_data['followers'].should == 1
            response.jsend_data['follow'].should_not be_nil
          end
          
          it "does not populate share when follow is a refollow" do
            follow.stubs(:refollow?).returns(true)
            click_follow_link(true)
            response.jsend_data.should be_nil
          end
        end

        context "when no follow is created" do
          before do
            subject.current_user.expects(:follow!).once.with(user).returns(nil)
          end

          it "does not populate share" do
            click_follow_link(true)
            response.jsend_data.should be_nil
          end
        end
      end

      def click_follow_link(remote=false)
        click_follow_model_link(:follow, remote)
      end
    end

    context "#unfollow" do
      it_behaves_like 'secured against anonymous users' do
        before { click_unfollow_link }
      end

      context "by a user" do
        include_context "for a logged-in user"
        before do
          User.expects(:find_by_slug!).with(user_slug).returns(user)
          subject.current_user.expects(:unfollow!).once.with(user)
        end

        it "succeeds" do
          click_unfollow_link
          response.should redirect_to(public_profile_path(user))
        end

        it "returns unfollow info" do
          controller.current_user.expects(:following?).with(user).returns(false)
          user.expects(:followers).returns([])
          click_unfollow_link(true)
          response.jsend_data['followers'].should == 0
          response.jsend_data['follow'].should_not be_nil
        end
      end

      def click_unfollow_link(remote=false)
        click_follow_model_link(:unfollow, remote)
      end
    end

    context "#block" do
      it_behaves_like 'secured against anonymous users' do
        before { click_block_link }
      end

      context "by a user" do
        include_context "for a logged-in user"
        before do
          User.expects(:find_by_slug!).with(user_slug).returns(user)
          subject.current_user.expects(:block!).once.with(user)
        end

        it "succeeds" do
          click_block_link
          response.should redirect_to(public_profile_path(user))
        end

        it "returns follow info" do
          user.expects(:followers).returns([])
          click_block_link(true)
          response.jsend_data['followers'].should == 0
          response.jsend_data['block'].should_not be_nil
        end
      end

      def click_block_link(remote=false)
        click_follow_model_link(:block, remote)
      end
    end

    context "#unblock" do
      it_behaves_like 'secured against anonymous users' do
        before { click_unblock_link }
      end

      context "by a user" do
        include_context "for a logged-in user"
        before do
          User.expects(:find_by_slug!).with(user_slug).returns(user)
          subject.current_user.expects(:unblock!).once.with(user)
        end

        it "succeeds" do
          click_unblock_link
          response.should redirect_to(public_profile_path(user))
        end

        it "returns follow info" do
          user.expects(:followers).returns([])
          click_unblock_link(true)
          response.jsend_data['followers'].should == 0
          response.jsend_data['block'].should_not be_nil
        end
      end

      def click_unblock_link(remote=false)
        click_follow_model_link(:unblock, remote)
      end
    end

    def click_follow_model_link(action, remote=false)
      params = {:public_profile_id => user_slug}
      if remote
        xhr :put, action, {:format => :json}.merge(params)
      else
        put action, params
      end
    end
  end
end
