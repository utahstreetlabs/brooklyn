#= require controls/infinite_scroll_manager

jQuery ->
  $loadingContainer = $('#loading-container')
  $container = $('.search-results')
  
  manager = new Copious.InfiniteScrollManager('.search-results', '#scroll-top')
  manager.on 'scroller:loading:start', -> $loadingContainer.show()
  manager.on 'scroller:loading:end', -> $loadingContainer.hide()
  manager.on 'scroller:more', (data) ->
    $elements = ($(c) for c in data.cards)
    $container.append($elements...)
    _.each $elements, ($element) -> $element.find('.ellipsis').dotdotdot()
  manager.start()
