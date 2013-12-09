class Feed::Listings::CommentsController < ApplicationController
  include Controllers::ListingScoped

  set_listing
  respond_to :json

  def create
    comment = @listing.comment(current_user, params[:comment], source: 'feed')
    if comment
      if comment.valid?
        data = {}
        data[:comment] = Feed::CommentExhibit.new(@listing, comment, current_user, view_context).render
        data[:comment_header] = Feed::CommentHeaderExhibit.new(@listing, current_user, view_context).render
        data[:comment_count] = @listing.comments_count
        data[:listingId] = @listing.id
        data[:commentId] = comment.id
        render_jsend(success: data)
      else
        render_jsend(fail: {errors: comment.errors})
      end
    else
      render_jsend(error: 'Service Unavailable', code: 503)
    end
  end
end
