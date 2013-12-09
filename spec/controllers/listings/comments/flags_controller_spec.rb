require 'spec_helper'

describe Listings::Comments::FlagsController do
  let(:listing) { stub_listing('Hobo Mascara', id: 456) }
  let(:commenter) { stub_user('Ric Ocasek', id: 789) }
  let(:comment) { stub_comment(commenter, 'this is a comment') }
  let(:reason) { 'spam' }
  let(:description) { 'Gutter is a tool' }
  let(:admin) { false }

  before { act_as_stub_user admin: admin }

  it "refuses to unflag a comment" do
    click_unflag_comment_button
    response.should be_jsend_error
    response.jsend_code.should == 401
  end

  context "with listing" do
    before do
      scope = mock('listing-scope')
      Listing.expects(:scoped).returns(scope)
      scope.expects(:find_by_slug!).with(listing.slug).returns(listing)
    end

    context "when comment does not exist" do
      before { listing.expects(:find_comment).with(comment.id).returns(nil) }

      it "returns jsend error" do
        click_flag_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 404
      end
    end

    context "when comment exists" do
      before { listing.expects(:find_comment).with(comment.id).returns(comment) }

      it "flags a comment successfully" do
        flag = stub('flag', persisted?: true, reason: 'spam')
        comment.expects(:create_flag).
          with(has_entries(user_id: subject.current_user.id, reason: reason, description: description)).
          returns(flag)
        ListingObserver.instance.expects(:after_comment_flagged).with(listing, comment, flag)
        Brooklyn::UsageTracker.expects(:async_track).with(:flag_listing_comment, is_a(Hash))
        click_flag_comment_button
        response.should be_jsend_success
        response.jsend_data['confirmation'].should have_flash_message(:created, scope: 'listings.comments.flags')
      end

      it "flags a comment unsuccessfully" do
        comment.expects(:create_flag).
          with(has_entries(user_id: subject.current_user.id, reason: reason, description: description)).
          returns(nil)
        ListingObserver.instance.expects(:after_comment_flagged).never
        Brooklyn::UsageTracker.expects(:async_track).never
        click_flag_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 503
      end

      context "as admin" do
        let(:admin) { true }

        it "flags a comment" do
          flag = stub('flag', persisted?: true, reason: 'spam')
          comment.expects(:create_flag).
            with(has_entries(user_id: subject.current_user.id, reason: reason, description: description)).
            returns(flag)
          ListingObserver.instance.expects(:after_comment_flagged).with(listing, comment, flag)
          Brooklyn::UsageTracker.expects(:async_track).with(:flag_listing_comment, is_a(Hash))
          User.expects(:where).with(id: [comment.user_id]).returns([commenter])
          click_flag_comment_button
          response.should be_jsend_success
          response.jsend_data['comment'].should be
        end

        it "unflags a comment" do
          comment.expects(:unflag)
          Brooklyn::UsageTracker.expects(:async_track).with(:unflag_listing_comment, is_a(Hash))
          User.expects(:where).with(id: [comment.user_id]).returns([commenter])
          click_unflag_comment_button
          response.should be_jsend_success
          response.jsend_data['comment'].should be
        end
      end
    end
  end

  def click_flag_comment_button
    xhr :post, :create, listing_id: listing.slug, comment_id: comment.id, reason: reason, description: description,
      format: :json
  end

  def click_unflag_comment_button
    xhr :post, :unflag, listing_id: listing.slug, comment_id: comment.id, format: :json
  end
end
