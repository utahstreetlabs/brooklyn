#= require controls/infinite_scroll_manager
#= require copious/tracking

jQuery ->
  $notificationCount = $('#notification-count')
  $('a.clear-notification').each ->
    $.remoteLink.initRemoteLink(this).bind('jsend:success', (event, data) ->
      $notification = $(".notification[data-notification='#{data.notificationId}']")
      $date = $notification.parent()
      $container = $date.parent()
      $notification.remove()
      if $date.children('.notification').length is 0
        $date.remove()
        if $container.children('.date').length is 0
          $container.append('<p>No notifications at this time.</p>')
      $notificationCount.html(parseInt($notificationCount.text()) - 1)
    )

  # Initialize infinite scroll manager
  $loadingContainer = $('#loading-container')
  $container = $('.notifications-container')

  manager = new Copious.InfiniteScrollManager('.notifications-container', '#scroll-top')
  manager.on 'scroller:loading:start', -> $loadingContainer.show()
  manager.on 'scroller:loading:end', -> $loadingContainer.hide()
  manager.on 'scroller:more', (data) ->
    $elements = ($(c) for c in data.cards)
    $container.append($elements...)
    _.each $elements, ($element) -> $element.find('.ellipsis').dotdotdot()
  manager.start()

  # Wrapped in its own function for konacha.
  # See: https://groups.google.com/forum/?fromgroups#!topic/sinonjs/MMYrwKIZNUU%5B1-25-false%5D
  COPIOUSNS ?= {}
  COPIOUSNS.redirectWindow = (url) ->
    window.location.href = url

  $(document).on 'click', '[data-role=notification]', ->
    if $(this).data('notifications-v2')
      COPIOUSNS.redirectWindow($(this).find('div[data-target]').data('target'))
      false

  copious.track_links('.mention-notification-link', 'listing_mention_notification click', (elem) ->
    $element = $(elem)
    {
      mentionee: $element.attr('data-mentionee-slug'),
      mentioner: $element.attr('data-mentioner-slug'),
      listing_title: $element.text()
    }
  )
