require 'spec_helper'

describe 'Add comment from listing modal' do
  let!(:listing) { FactoryGirl.create(:active_listing) }
  let(:comment_text) { "Way down in Hades Town" }
  let(:comment) { stub('comment', text: comment_text, keywords: {}, valid?: true) }

  before do
    InternalListing.any_instance.stubs(:likes_count).returns(23)
    InternalListing.any_instance.stubs(:comment_summary).returns(stub('comment-summary', comments: {}))
    InternalListing.any_instance.stubs(:comment).returns(comment)
  end

  it_behaves_like 'an anonymous request', xhr: true do
    before do
      add_comment
    end
  end

  context "when logged in" do
    include_context 'an authenticated session'

    context "with valid params" do
      it 'updates the comment stream' do
        add_comment
        expect(response).to be_jsend_success
        expect(response.jsend_data[:comment]).to be
      end
    end

    context "with invalid params" do
      let(:comment_text) { '' }
      before do
        comment.stubs(:valid?).returns(false)
        comment.stubs(:errors).returns({})
      end

      it 'updates the comment stream' do
        add_comment
        expect(response).to be_jsend_failure
        expect(response.jsend_data[:errors]).to be
      end
    end

    context "when the comment service is unavailable" do
      before do
        InternalListing.any_instance.stubs(:comment).returns(nil)
      end

      it 'returns an error' do
        add_comment
        expect(response).to be_jsend_error
      end
    end
  end

  def add_comment
    xhr(:post, "/listings/#{listing.to_param}/modal/comments" , format: :json,
      comment: {text: comment_text}, keywords: {}, source: "listing-modal")
  end
end
