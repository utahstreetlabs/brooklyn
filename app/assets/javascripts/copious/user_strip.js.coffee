jQuery ->
  UserStrip =
    options: {}
    _create: ->
      $strip = this
      $strip.following = $strip.element.data 'following'
      $strip._initFollowButton()
    _initFollowButton: ->
      $strip = this
      $strip.followButton = $('.follow-button', $strip.element)
      $.remoteLink.initRemoteLink $strip.followButton
      $strip.followersCount = $('[data-role=followers-count]', $strip.element)
      $strip.followButton.on 'jsend:success', (event, data) ->
        if data.following != undefined
          $strip.following = data.following
          $strip.element.trigger 'userStrip:followed', [data.following]
        if data.button != undefined
          $strip.updateFollowButton data.button
        if data.followersCount != undefined
          $strip.updateFollowersCount data.followersCount
    updateFollowButton: (html) ->
      $strip = this
      $strip.followButton.replaceWith html
      $strip._initFollowButton()
    updateFollowersCount: (count) ->
      $strip = this
      $strip.followersCount.html count
  $.widget "copious.userStrip", UserStrip
