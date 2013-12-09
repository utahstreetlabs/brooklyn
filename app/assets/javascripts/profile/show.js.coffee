#= require controls/infinite_scroll_manager

jQuery ->
  viewingSelf = $('[data-self=true]').length > 0

  $('[data-role=tag-card]').each ->
    $(this).tagCard()

  $('[data-role=user-strip]').each ->
    $strip = $(this)
    $strip.userStrip()
    if viewingSelf
      $strip.on 'userStrip:followed', (event, following) ->
        $('[data-role=profile-following-count]').each ->
          $el = $(this)
          count = parseInt $el.text()
          count = if following then count+1 else count-1
          $el.html(count)

  $loadingContainer = $('#loading-container')
  $container = $('.search-results')

  manager = new Copious.InfiniteScrollManager('.search-results', '#scroll-top')
  manager.on 'scroller:loading:start', -> $loadingContainer.show()
  manager.on 'scroller:loading:end', -> $loadingContainer.hide()
  manager.on 'scroller:more', (data) ->
    $elements = ($(c) for c in data.cards)
    $container.append($elements...)
    _.each $elements, ($element) -> $element.find('.ellipsis').dotdotdot(wrap: 'letter')
  manager.start()
