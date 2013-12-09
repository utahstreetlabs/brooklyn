class Listings::Comments::FlagsController < ApplicationController
  include Controllers::ListingScoped
  include Controllers::CommentScoped

  before_filter :require_admin, only: :unflag

  set_listing
  set_comment

  def create
    attrs = {reason: params[:reason], description: params[:description], user_id: current_user.id}
    logger.debug("Flagging comment #{@comment.id} for listing #{@listing.id} as user #{current_user.id}")
    flag = @comment.create_flag(attrs)
    respond_to do |format|
      format.json do
        if flag
          if flag.persisted?
            # XXX: this totally doesn't belong here, but need some rework to make comment observable.
            ListingObserver.instance.after_comment_flagged(@listing, @comment, flag)
            track_usage(:flag_listing_comment)
            render_jsend(
              success: Listings::CommentedExhibit.create(@listing, @comment, current_user, view_context,
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
    Rails.logger.debug("Unflagging comment #{@comment.id} for listing #{@listing.id} as user #{current_user.id}")
    @comment.unflag
    track_usage(:unflag_listing_comment)
    respond_to do |format|
      format.json {
        render_jsend(success: Listings::CommentedExhibit.create(@listing, @comment, current_user, view_context).render)
      }
    end
  end
end
