class TagObserver < ObserverBase
  def after_like(tag, liker, like, options = {})
    Tags::AfterLikeJob.enqueue(tag.id, liker.id, options)
    track_usage(:like_tag, tag: tag.slug, user: liker)
  end

  def after_unlike(tag, unliker, options = {})
    Tags::AfterUnlikeJob.enqueue(tag.id, unliker.id, options)
    track_usage(:unlike_tag, tag: tag.slug, user: unliker)
  end
end
