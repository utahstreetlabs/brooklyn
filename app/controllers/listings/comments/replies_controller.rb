class Listings::Comments::RepliesController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::CommentScoped

  set_flash_scope 'listings.comments.replies'
  set_listing
  before_filter :require_admin, only: [:destroy, :resend_email]
  set_comment

  def create
    Rails.logger.debug("Replying to comment #{@comment.id} for listing #{@listing.id} as user #{current_user.id}")
    attrs = {text: params[:text], user_id: current_user.id,
             keywords: (params[:comment].present? ? params[:comment][:keywords] : nil)}
    reply = @listing.reply(current_user, @comment, attrs, params)
    respond_to do |format|
      format.json do
        if reply
          if reply.valid?
            render_jsend(
              success: Listings::CommentedExhibit.create(@listing, @comment, current_user, view_context,
                extras: {listingId: @listing.id, commentId: @comment.id}, keywords: reply.keywords
              ).render)
          else
            render_jsend(fail: {errors: reply.errors})
          end
        else
          render_jsend(error: 'Service Unavailable', code: 503)
        end
      end
    end
  end

  def destroy
    Rails.logger.debug("Deleting reply #{params[:id]} to comment #{@comment.id} for listing #{@listing.id}")
    @comment.delete_reply(params[:id])
    track_usage(:delete_listing_comment_reply)
    respond_to do |format|
      format.json do
        render_jsend(
          success: Listings::CommentedExhibit.create(@listing, nil, @comment, view_context,
            confirmation: localized_flash_message(:deleted, {scope: 'listings.comments.replies'})
          ).render)
      end
    end
  end

  def resend_email
    commenter = User.find(@comment.user_id)
    reply = @comment.replies.detect { |r| r.id == params[:reply_id] }
    replier = User.find(reply.user_id)
    if commenter != replier
      Listings::AfterCommentedJob.email_replied(@listing, commenter, @comment, replier, {id: reply.id})
      render_jsend(
        success: Listings::CommentedExhibit.create(@listing, reply, commenter, view_context,
          original_comment: @comment,
          extras: {
            listingId: @listing.id,
            commentId: reply.id,
            message: localized_flash_message(:email_resent)
        }).render)
    else
      render_jsend(error: 'Will not send reply email when replier is also commenter', code: 403)
    end
  end
end
