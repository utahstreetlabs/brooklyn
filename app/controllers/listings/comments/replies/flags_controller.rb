class Listings::Comments::Replies::FlagsController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::CommentScoped

  before_filter :require_admin, only: :unflag

  set_listing
  set_comment

  before_filter do
    @reply = @comment.replies.find {|reply| reply.id == params[:reply_id]}
    respond_not_found unless @reply
  end

  def create
    attrs = {reason: params[:reason], description: params[:description], user_id: current_user.id}
    logger.debug("Flagging reply %s to comment %s for listing %s as user %s" %
      [@reply.id, @comment.id, @listing.id, current_user.id])
    flag = @reply.create_flag(attrs)
    respond_to do |format|
      format.json do
        if flag
          if flag.persisted?
            ListingObserver.instance.after_comment_flagged(@listing, @reply, flag)
            track_usage(:flag_listing_comment_reply)
            render_jsend(
              success: Listings::CommentedExhibit.create(@listing, @reply, current_user, view_context,
                admin? ? {} : {confirmation: localized_flash_message(:created, scope: 'listings.comments.flags')}
              ).render)
          else
            render_jsend(error: 'Bad Request', code: 400, data: {errors: flag.errors})
          end
        else
          render_jsend(error: 'Service Unavailable', code: 503)
        end
      end
    end
  end

  def unflag
    logger.debug("Unflagging reply %s to comment %s for listing %s" % [@reply.id, @comment.id, @listing.id])
    @reply.unflag
    track_usage(:unflag_listing_comment_reply)
    respond_to do |format|
      format.json {
        render_jsend(success: Listings::CommentedExhibit.create(@listing, @reply, current_user, view_context).render)
      }
    end
  end
end
