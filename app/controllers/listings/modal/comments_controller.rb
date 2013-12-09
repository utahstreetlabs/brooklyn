class Listings::Modal::CommentsController < ApplicationController
  include Controllers::ListingScoped

  set_listing
  respond_to :json

  def create
    comment = @listing.comment(current_user, params[:comment], params)
    if comment
      if comment.valid?
        # Pass keywords so we can generate FB u2u requests for FB users from keyword mentions
        render_jsend(
          success: Listings::CommentedExhibit.create(@listing, comment, current_user, view_context,
            modal: true, keywords: comment.keywords
          ).render)
      else
        render_jsend(fail: {errors: comment.errors})
      end
    else
      render_jsend(error: 'Service Unavailable', code: 503)
    end
  end

  protected
    def comment_params
      params[:comment].slice(:text, :keywords)
    end
end
