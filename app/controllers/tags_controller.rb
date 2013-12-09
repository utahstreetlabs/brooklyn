class TagsController < ApplicationController
  skip_before_filter :require_login_only, only: :autocomplete
  skip_action_event only: :autocomplete
  respond_to :json, :only => [:autocomplete, :typeahead]
  before_filter :load_tag, only: [:like, :unlike]

  def autocomplete
    tags = Tag.find_matching(params[:query], primary: params[:primary], limit: (params[:limit] || 10),
      type: params[:type])
    respond_with({options: tags.map(&:name)})
  end

  def typeahead
    tags = Tag.find_matching(params[:query], primary: params[:primary], limit: (params[:limit] || 10),
      type: params[:type])
    render_jsend(success: {options: tags.map { |t| {slug: t.slug, name: t.name} }})
  end

  def like
    like = current_user.like(@tag)
    track_usage(:like_tag)
    respond_to_like_unlike(@tag, true)
  end

  def unlike
    current_user.unlike(@tag)
    track_usage(:unlike_tag)
    respond_to_like_unlike(@tag, false)
  end

protected
  def load_tag
    @tag = Tag.find_by_slug!(params[:tag_id])
  end

  def respond_to_like_unlike(user, liked)
    respond_to do |format|
      format.json do
        name = (params['name'] == 'true')
        new_params = {name: name}
        options = {like_path: tag_like_path(@tag, new_params), unlike_path: tag_unlike_path(@tag, new_params), action: "like", role: "love-button", link: "remote"}
        options = options.merge(like_text: "Love #{@tag.name}", liked_text: "Loved #{@tag.name}") if name
        button = view_context.tag_like_button(@tag.id, liked, options)
        render_jsend(success: {button: button, liked: liked})
      end
    end
  end
end
