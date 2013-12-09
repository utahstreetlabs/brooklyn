#= require copious/jquery.searchboxwidget
#= require copious/tracking
#= require controls/layout/hamburger

jQuery ->
  $('#search_box').searchboxwidget()

  copious.track_links('#masthead-logo', 'nav_logo click')

  $(document).on 'click', '#masthead-add-button', (e) ->
    $target = $(e.target)
    copious.track('nav_add click', username: $target.data('user'), source: copious.source($target))

  $(document).on 'hamburger:opened', (e, options = {}) =>
    $('body').css('overflow-x', 'hidden')
    $content = $('.hb-neighbor')
    $content.addClass('hamburger-opened')
    if options.animate
      $content.animate({'margin-left': Hamburger.width})
    else
      $content.css('margin-left', Hamburger.width)

  $(document).on 'hamburger:closed', (e, options = {}) =>
    $('body').css('overflow-x', 'auto')
    $content = $('.hb-neighbor')
    $content.removeClass('hamburger-opened')
    if options.animate
      $content.animate({'margin-left': '0px'})
    else
      $content.css('margin-left', '0px')
