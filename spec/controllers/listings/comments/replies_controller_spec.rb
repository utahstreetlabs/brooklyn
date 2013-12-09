require 'spec_helper'

describe Listings::Comments::RepliesController do
  context "as a user" do
    let(:listing) { stub_listing('Hobo Mascara', id: 456) }
    let(:listing_url) { "http://test.host/listings/#{listing.to_param}" }
    let(:commenter) { stub_user('Ric Ocasek', id: 789) }
    let(:comment) { stub_comment(commenter, 'this is a comment') }
    let(:reply) { stub_comment(commenter, 'this is a reply', id: 'cafebebe', parent_id: comment.id) }

    before do
      act_as_stub_user(user: commenter)
      scope = mock('listing-scope')
      Listing.expects(:scoped).returns(scope)
      scope.expects(:find_by_slug!).with(listing.slug).returns(listing)
    end

    context "when comment does not exist" do
      before { listing.expects(:find_comment).with(comment.id).returns(nil) }

      it "fails to create reply" do
        click_reply_to_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 404
      end

      it "fails to delete reply" do
        act_as_stub_user(admin: true)
        click_delete_reply_button
        response.should be_jsend_error
        response.jsend_code.should == 404
      end
    end

    context "when comment exists" do
      before { listing.expects(:find_comment).with(comment.id).returns(comment) }

      it "posts a reply" do
        reply.stubs(:valid?).returns(true)
        reply.stubs(:keywords).returns({})
        listing.expects(:reply).
          with(commenter, comment, has_entries(user_id: subject.current_user.id, text: reply.text, keywords: nil),
               is_a(Hash)).
          returns(reply)
        User.expects(:where).with(id: [commenter.id]).returns([commenter])
        click_reply_to_comment_button
        response.should be_jsend_success
        response.jsend_data['comment'].should be
      end

      it "fails to post an invalid reply" do
        reply.stubs(:valid?).returns(false)
        reply.stubs(:errors).returns([])
        listing.expects(:reply).with(commenter, comment, is_a(Hash), is_a(Hash)).returns(reply)
        click_reply_to_comment_button
        response.should be_jsend_failure
        response.jsend_data['errors'].should be
      end

      it "fails to create a comment when there is a server error" do
        listing.expects(:reply).with(commenter, comment, is_a(Hash), is_a(Hash)).returns(nil)
        click_reply_to_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 503
      end

      it "deletes a reply" do
        act_as_stub_user(admin: true)
        comment.expects(:delete_reply).with(reply.id)
        Brooklyn::UsageTracker.expects(:async_track).with(:delete_listing_comment_reply, is_a(Hash))
        click_delete_reply_button
      end
    end

    def click_reply_to_comment_button
      xhr :post, :create, listing_id: listing.slug, comment_id: comment.id, text: reply.text, format: :json
    end

    def click_delete_reply_button
      xhr :delete, :destroy, listing_id: listing.slug, comment_id: comment.id, id: reply.id, format: :json
    end
  end
end
