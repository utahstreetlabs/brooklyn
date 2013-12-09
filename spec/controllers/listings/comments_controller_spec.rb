require 'spec_helper'

describe Listings::CommentsController do
  let(:listing) { stub_listing('Hobo Mascara', id: 456) }
  let(:listing_url) { "http://test.host/listings/#{listing.to_param}" }
  let(:commenter) { stub_user('Ric Ocasek', id: 789) }
  let(:comment) { stub_comment(commenter, 'this is a comment') }

  context "as a user" do

    before do
      scope = mock('listing-scope')
      Listing.expects(:scoped).returns(scope)
      scope.expects(:find_by_slug!).with(listing.slug).returns(listing)
    end

    context "as regular user" do
      let(:admin) { false }

      before do
        act_as_stub_user admin: admin
      end

      it "creates a comment" do
        comment.stubs(:valid?).returns(true)
        comment.stubs(:keywords).returns({})
        subject.stubs(:prompt_share?).with(:listing_commented, anything).returns(true)
        listing.expects(:comment).
                with(subject.current_user, has_entries('text' => comment.text), is_a(Hash)).
                returns(comment)
        User.expects(:where).with(id: [comment.user_id]).returns([commenter])
        click_post_comment_button
        response.should be_jsend_success
        response.jsend_data['comment'].should be
      end

      context 'when comment contains keywords' do
        let(:hashtags) { {'yellow' => {'type' => 'tag', 'name' => 'Yellow', 'id' => 'yellow'}} }
        let(:keywords) { hashtags.merge('sly-stone' => {'type' => 'cf', 'name' => 'Sly Stone', 'id' => 'sly-stone'}) }
        let(:keyword_json) { ActiveSupport::JSON.encode(keywords) }

        it 'assigns tags from hashtags' do
          comment.stubs(:valid?).returns(true)
          comment.stubs(:keywords).returns(keywords)
          subject.stubs(:prompt_share?).with(:listing_commented, anything).returns(true)
          listing.expects(:comment).
                  with(subject.current_user, has_entries('text' => comment.text, 'keywords' => keyword_json),
                       is_a(Hash)).
                  returns(comment)
          User.expects(:where).with(id: [comment.user_id]).returns([commenter])
          click_post_comment_button(keyword_json)
          response.should be_jsend_success
          response.jsend_data['comment'].should be
        end
      end

      it "fails to create an invalid comment" do
        comment.stubs(:valid?).returns(false)
        comment.stubs(:errors).returns([])
        listing.expects(:comment).with(subject.current_user, is_a(Hash), is_a(Hash)).returns(comment)
        click_post_comment_button
        response.should be_jsend_failure
        response.jsend_data['errors'].should be
      end

      it "fails to create a comment when there is a server error" do
        listing.expects(:comment).
                with(subject.current_user, has_entries('text' => comment.text), is_a(Hash)).
                returns(nil)
        click_post_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 503
      end

      it "refuses to delete a comment" do
        listing.expects(:delete_comment).never
        click_delete_comment_button
        response.should be_jsend_error
        response.jsend_code.should == 401
      end
    end

    context "as admin" do
      let(:admin) { true }

      before { act_as_stub_user admin: admin }

      it "deletes a comment" do
        listing.expects(:delete_comment).with(comment.id, subject.current_user)
        click_delete_comment_button
        response.should be_jsend_success
        response.jsend_data['confirmation'].should have_flash_message('listings.comments.deleted')
      end
    end

    def click_post_comment_button(keywords = nil)
      comment_hash = {text: comment.text}
      comment_hash[:keywords] = keywords if keywords
      xhr :post, :create, listing_id: listing.slug, comment: comment_hash, format: :json
    end

    def click_delete_comment_button
      xhr :delete, :destroy, listing_id: listing.slug, id: comment.id, format: :json
    end
  end
end
