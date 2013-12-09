#= require copious/plugin
#= require copious/tracking
#= require controls/scrollable
#= require underscore

class Hamburger
  @width: '270px'
  @closedLeftOffset: "-#{Hamburger.width}"
  @openLeftOffset: '0px'
  @minWindowWidth: 1240

  constructor: (@control, @tray) ->
    # General notes:
    # Hamburger behaves differently between larger and smaller screens (threshold is at 1240px width).
    # On smaller screens, the hamburger does not animate when opening/closing and does not use the custom JS scrollbar.
    # This is to improve UX on mobile devices as JS animations and scrollbars are not as smooth on mobile devices.
    # We change the behavior based on screen width rather than checking user agent for mobile browsers due to
    # unreliability of user agent and maintenance required to keep track of all mobile user agents.

    @button = @control.find('[data-toggle=hamburger]')
    @totalPill = @control.find('[data-role=total-pill]')
    @storyPill = @control.find('[data-role=story-pill]')
    @notificationPill = @control.find('[data-role=notification-pill]')
    @searchForm = @tray.find('form')
    @scrollbar = @tray.find('#hb-tray-contents').scrollable('instance') if window.innerWidth > Hamburger.minWindowWidth
    @window = $(window)
    @isOpen = false

    this._initState()
    this._initAutoToggle()
    this._initScroll()

    @button.on 'click', => this.toggle({animate: this._animateEnabled(), userTriggered: true})

    # the hamburger pill shows the total count of new stories and unread notifications. each poller updates an invisible
    # pill element and then triggers `hamburger:pill:updated`. a handler for that event sums the individual pill counts
    # and updates the aggregate pill with the new total.

    $(document).on 'storycount:updated', @storyPill, =>
      $(document).trigger('hamburger:pill:updated')

    $(document).on 'notificationcount:updated', @notificationPill, =>
      $(document).trigger('hamburger:pill:updated')

    $(document).on 'hamburger:pill:updated', =>
      total = this.totalCount()
      if total > 0
        @totalPill.html(total)
        @totalPill.addClass('in').show() unless @isOpen
      else
        @totalPill.html('').removeClass('in').hide()

    # tab behavior

    @searchForm.on 'submit', =>
      @searchForm.find('.spinner').show()

    @tray.on 'click', '#browse-tab', (e) =>
      # Async refresh scrollbar to calculate scrollable content after expanding tab
      setTimeout((=> @scrollbar.refresh()), 0) if @scrollbar?

    # tracking

    $(document).on 'hamburger:opened', (e, data = {}) =>
      if data.userTriggered
        copious.track('nav_hamburger click', nav_state: 'clicking_to_open', hamburger_counter: this.totalCount())

    $(document).on 'hamburger:closed', (e, data = {}) =>
      if data.userTriggered
        copious.track('nav_hamburger click', nav_state: 'clicking_to_close', hamburger_counter: this.totalCount())

    copious.track_forms("#search-tab form", 'nav_search_box search', (form) =>
      {search_term: $(form).find('input[name=search]').val()}
    )
    copious.track_links('#home-tab a', 'nav_home click')
    copious.track_links('#profile-tab a', 'nav_profile click')
    copious.track_links('#notifications-tab a', 'nav_notifications click',
                        notifications_counter: this.notificationCount())
    copious.track_links('#feed-tab a', 'nav_feed click', feed_counter: this.storyCount())
    copious.track_links('#trending-tab a', 'nav_trending click')
    copious.track_links('#new-arrivals-tab a', 'nav_new_arrivals click')
    copious.track_links('#browse-tab a', 'nav_browse click', (a) => {category: $(a).data('category')})
    copious.track_links('#settings-tab a', 'nav_settings click')
    copious.track_links('#dashboard-tab a', 'nav_dashboard click')
    copious.track_links('#logout-tab a', 'nav_logout click')

  open: (options = {}) =>
    @button.addClass('active')
    @totalPill.hide()
    if options.animate
      @tray.animate({left: Hamburger.openLeftOffset})
    else
      @tray.css('left', Hamburger.openLeftOffset)
    # Timeout necessary to trigger event asynchronously when we open tray on load
    # Avoids race condition of when event triggered vs when handler attached
    @isOpen = true
    setTimeout((-> $(document).trigger 'hamburger:opened', options), 0)

  close: (options = {}) =>
    @button.removeClass('active')
    @totalPill.show()
    if options.animate
      @tray.animate({left: Hamburger.closedLeftOffset})
    else
      @tray.css('left', Hamburger.closedLeftOffset)
    @isOpen = false
    setTimeout((-> $(document).trigger 'hamburger:closed', options), 0)

  toggle: (options = {}) =>
    if @button.hasClass('active')
      this.close(options)
    else
      this.open(options)

  storyCount: =>
    count = parseInt(@storyPill.text())
    if _.isNaN(count) then 0 else count

  notificationCount: =>
    count = parseInt(@notificationPill.text())
    if _.isNaN(count) then 0 else count

  totalCount: =>
    this.storyCount() + this.notificationCount()

  _initState: =>
    # Complete open process if hamburger nav is open by default.
    this.open(false) if @tray.css('left') is Hamburger.openLeftOffset

  _initAutoToggle: =>
    if $('[data-hb-auto=true]').exists()
      @prevWindowWidth = window.innerWidth
      @window.resize =>
        currWindowWidth = window.innerWidth
        # Only open/close the hamburger nav if window has been resized past the threshold.
        if currWindowWidth <= Hamburger.minWindowWidth and @prevWindowWidth > Hamburger.minWindowWidth
          this.close({animate: true}) if @isOpen
        else if currWindowWidth > Hamburger.minWindowWidth and @prevWindowWidth <= Hamburger.minWindowWidth
          this.open({animate: true}) unless @isOpen
        @prevWindowWidth = currWindowWidth

  _initScroll: =>
    @window.resize(=> @scrollbar.refresh()) if @scrollbar? and @scrollbar.refresh?

    # Prevent hamburger scroll from scrolling page when reaching top/bot of hamburger.
    # Note: This requires the mousewheel plugin used by the Scrollable component.
    height = @tray.height()
    @tray.on 'mousewheel', (e, delta) =>
      # delta < 0 when scrolling down, delta > 0 when scrolling up
      scrollTop = @tray.scrollTop()
      scrollHeight = @tray.get(0).scrollHeight
      if (scrollTop is 0 and delta > 0) or (scrollTop is (scrollHeight - height) and delta < 0)
        e.preventDefault()

  _animateEnabled: =>
    window.innerWidth > Hamburger.minWindowWidth

jQuery ->
  window.Hamburger = Hamburger
  $.fn.hamburger = copious.plugin.componentPlugin(Hamburger, 'hamburger')
  $('#hb-hamburger').hamburger($('#hb-tray'))
