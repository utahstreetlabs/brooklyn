class Profiles::FollowController < ApplicationController
  include Controllers::ProfileScoped
  include Controllers::Jsendable

  load_profile_user
  customize_action_event variables: [:profile_user]

  def follow
    follow = current_user.follow!(@profile_user)
    respond_to_follow_unfollow(@profile_user, current_user)
  end

  def unfollow
    current_user.unfollow!(@profile_user)
    respond_to_follow_unfollow(@profile_user, current_user)
  end

  def block
    current_user.block!(@profile_user)
    respond_to_block_unblock(@profile_user, current_user)
  end

  def unblock
    current_user.unblock!(@profile_user)
    respond_to_block_unblock(@profile_user, current_user)
  end

  def typeahead
    users = current_user.followers_by_prefix(params[:query], limit: 20, fields: [:id, :name, :profile_photo])
    suggestions = users.map { |u| {name: u.name, id: u.id, imgUrl: u.profile_photo.url(:px_50x50)} }
    render_jsend(success: { options: suggestions })
  end

  protected

  def respond_to_follow_unfollow(followee, follower, data={})
    respond_to do |format|
      format.html { redirect_to public_profile_path(followee) }
      format.json do
        result = {
          followeeId: followee.id,
          follow: render_follow_button(followee, follower),
          followers: followee.followers.count
        }
        render_jsend(success: result.merge(data))
      end
    end
  end

  def render_follow_button(followee, follower)
    # XXX: rewrite using an exhibit
    view_context.follow_control(followee, follower, follower_count_selector: '[data-role=profile-followers-count]',
                                text_for: params[:text_for], no_text: true)
  end

  def respond_to_block_unblock(blockee, blocker)
    respond_to do |format|
      format.html { redirect_to public_profile_path(blockee) }
      format.json do
        render_jsend(success: {block: render_block_button(blockee, blocker),
          followers: blockee.followers.count})
      end
    end
  end

  def render_block_button(blockee, blocker)
    render_to_string partial: '/shared/block_button.html', locals: {blockee: blockee, blocker: blocker}
  end
end

