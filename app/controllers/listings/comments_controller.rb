class Listings::CommentsController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::CommentScoped

  set_flash_scope 'listings.comments'
  set_listing
  before_filter :require_admin, only: [:destroy, :resend_email]
  set_comment only: [:share, :resend_email]

  def create
    comment = @listing.comment(current_user, params[:comment], params)
    respond_to do |format|
      format.json do
        if comment
          if comment.valid?
            # Pass keywords so we can generate FB u2u requests for FB users from keyword mentions
            render_jsend(
              success: Listings::CommentedExhibit.create(@listing, comment, current_user, view_context,
                extras: {listingId: @listing.id, commentId: comment.id}, keywords: comment.keywords
              ).render)
          else
            render_jsend(fail: {errors: comment.errors})
          end
        else
          render_jsend(error: 'Service Unavailable', code: 503)
        end
      end
    end
  end

  def destroy
    @listing.delete_comment(params[:id], current_user)
    respond_to do |format|
      format.json do
        render_jsend(
          success: Listings::CommentedExhibit.create(@listing, nil, current_user, view_context,
            confirmation: localized_flash_message(:deleted, {scope: 'listings.comments'})
          ).render)
      end
    end
  end

  def resend_email
    commenter = User.find(@comment.user_id)
    if @listing.seller != commenter
      Listings::AfterCommentedJob.email_commented(@listing, commenter, {id: @comment.id})
      render_jsend(
        success: Listings::CommentedExhibit.create(@listing, @comment, commenter, view_context,
          extras: {listingId: @listing.id, commentId: @comment.id, message: localized_flash_message(:email_resent)}
        ).render)
    else
      render_jsend(error: 'Will not send comment email to seller for own comment', code: 403)
    end
  end
end
