#= require jquery.history
#= require copious/feature_flags

#######################################################################################################################
#
# HistoryManager provides an interface with which to modify the browser history and handle browser navigation.
# Changes to the browser history should only be done through HistoryManager.
#
# HistoryManager should exist on every page within the application. When adding new history entries to the browser,
# they are not treated as "new pages". So when clicking back/forward on history entries we create, the browser
# does nothing except changing the URL. If a page is reloaded, the JS components are also reloaded and all modified
# markup, JS component states, and HistoryManager properties may be lost. However, state data will still exist.
# Thus, HistoryManager must always exist on the page to handle browser navigation events based on available state data.
#
# Note that HistoryManager uses a modified version of history.js that includes PRs not yet merged with the master
# branch. history.js can be found at:
#   https://github.com/browserstate/history.js
#
# Function usage:
#   enabled: checks whether HistoryManager is enabled.
#
#   getData: retrieves data for component from current history state.
#     component: name of component calling the function.
#     options: supports options:
#       - property: return data from the property of the component
#
#   getDataProperty: retrieves property of component data that was saved with addData options.property
#
#   addData: adds data for a component to the current history state.
#     component: name of component calling the function.
#     data: object containing data to be saved.
#       - The url property will be set as the new URL if it exists.
#     options: supports options:
#       - newEntry: If true, add new history state after current. Clears all history entries after new one, and data
#         from old history state will not be accessible with getData anymore.
#       - property: Set data for the property of the given component.
#
#   addStateHandler: adds a handler for history state change events.
#     context: should usually be `this` when function is called.
#     component: name of component the handler manages.
#     order: represents priority of handler to determine order handlers are called.
#     method: handler function to be called on state change event.
#     args: array of arguments to provide handler method at time of state change event.
#
# General usage:
#   - Components that use HistoryManager should check HistoryManager.enabled before setting up history support.
#
#   - Components should not save data for or have access to data from other components.
#
#   - Components that use addData should _always_ add a history state change event handler with addStateHandler.
#     This is so the history manager is aware that the component is actively changing or monitoring the history.
#     It also avoids the _defaultHandler being called when there aren't any history components on the page.
#
#   - The history manager handles passing relevant state data to handlers on state change events.
#     It also passes the previous URL and state data for the component, and additional arguments when adding the
#     handler. Passed data is in the format:
#       { savedDataProperty: value, prevRelUrl: <string>, prevStateData: <object> }
#
#   - Components that add state change handlers to HistoryManager should _only_ deal with changing the content
#     on the page and _never_ modify the history state or URL. Doing so would cause trigger the handler again
#     and cause an infinite loop.
#
#   - Components should attach options to the current history state using to PROC_HANDLERS_START or PROC_HANDLERS_END
#     events when some action needs to be performed by HistoryManager before or after executing state change handlers.
#     - Options are added with `addData(HistoryManager.PROC_HANDLERS_[START|END], options)`.
#     - Options should be used for cases where no handler is expected to exist for the component (e.g. page is reloaded
#       and handler has not been added to HistoryManager).
#
#   - History state change events are triggered when clicking the browser back/forward buttons and when calling
#     HistoryManager.addData.
#
#   - History state change may also be triggered on page load. Don't rely on this behavior though as it may differ
#     between browsers.
#
#   - Calling getData without arguments will return an object with data from all components.
#     getData should only be called without arguments by HistoryManager itself.
#
# Notes:
#   - Handlers persist across history states but not across new pages (when user is redirected to new URL _and_ page
#     reloads.
#     - Handler methods cannot be stored in history state, as methods are serialized and lost after state change:
#       http://stackoverflow.com/questions/7986601/history-js-onpopstate#comment14084654_9339053
#
# Example:
#   Consider the case where we have a series of tabs for a <div>. Clicking a tab changes the contents of the <div>
#   and we want to change the URL to be that of the page containing details about the <div> contents.
#
#   Setup:
#     return unless HistoryManager.enabled
#     stateData = {action: 'default', url: document.URL}
#     HistoryManager.addData(HistoryManager.components.tabs, stateData)
#     HistoryManager.addStateHandler(this, HistoryManager.components.tabs, _tabHandler)
#
#   Tab click:
#     stateData = {action: 'update', url: $tab.data('url')}
#     HistoryManager.addData(HistoryManager.components.tabs, stateData, {newEntry: true})
#
#   Tab state change handler:
#     _tabHandler: (data) ->
#       return unless data?
#       _loadTabContent($div, data.url)
#
#######################################################################################################################
class HistoryManager
  constructor: ->
    # Names of components that use HistoryManager
    @components =
      searchFacet: 'searchFacet'
      scroll: 'scroll'
      listingModal: 'listingModal'
    # Priority values of event handlers for history state change events
    # Represents order of execution, where a lower number handler is executed sooner
    @priorities =
      searchFacet: 10
      scroll: 20
      listingModal: 30

    # Names of HistoryManager events for other components to listen and add options for
    @PROC_HANDLERS_START = 'history.processHandlers:start'
    @PROC_HANDLERS_END = 'history.processHandlers:end'

    @_handlers = []
    @_prevRelUrl = location.pathname + location.search
    @_prevStateData = this.getData()

    # Store hack variables and functions to deal with browser quirks.
    @hacks =
      # Browsers automatically save scroll positions when leaving and re-entering pages.
      # After modifying the browser history, browsers may not be aware of when we are actually changing pages
      # and inappropriately save or load scroll positions. Use this method before such cases happen to prevent this.
      # Be careful of calling this in places where it may block user scroll (although in many cases the user
      # will not notice due to the distance scrolled with each event and the number of times the scroll event fires).
      preventBrowserScroll: (options = {}) ->
        if options.blockFirst
          scrollPos = $(window).scrollTop()
          $(document).on 'scroll.history.hack', ->
            $(window).scrollTop(scrollPos)
            $(document).off 'scroll.history.hack'

    return unless this.enabled()
    History.Adapter.bind window, 'statechange', (e) =>
      this._beforeProcessHandlers()
      this._processHandlers(@_handlers, @_prevStateData, @_prevRelUrl)
      this._afterProcessHandlers()
      @_prevRelUrl = location.pathname + location.search
      @_prevStateData = this.getData()

  enabled: =>
    History.enabled and copious.featureEnabled('history_manager')

  getData: (component, options = {}) =>
    return null unless this.enabled()
    data = History.getState().data
    if component?
      componentData = data[component]
      if componentData? and options.property?
        return componentData[options.property] or null
      componentData or null
    else
      data

  getDataProperty: (data, property) =>
    data[property] or null if data? and property?

  addData: (component, data, options = {}) =>
    # Note: browser URL is set to data.url if present
    return unless this.enabled()
    state = History.getState()
    stateData = if options.newEntry? then {} else state.data
    stateData.url = location.href
    if options.property?
      stateData[component] = {} unless stateData[component]?
      stateData[component][options.property] = data
    else
      stateData[component] = data
    if options.newEntry
      History.pushState(stateData, state.title, data.url or state.url)
    else
      History.replaceState(stateData, state.title, data.url or state.url)

  addStateHandler: (context, component, method, args = []) =>
    return unless this.enabled()
    @_handlers.push({context: context, component: component, method: method, args: args})

  _comparePriority: (a, b) =>
    aComp = a.component
    bComp = b.component
    return -1 unless typeof @priorities[bComp]?
    return 1 unless typeof @priorities[aComp]?
    return -1 if @priorities[aComp] < @priorities[bComp]
    return 1 if @priorities[aComp] > @priorities[bComp]
    0

  _getDataComponent: (data, component) =>
    data[component]

  _beforeProcessHandlers: =>
    options = this.getData(@PROC_HANDLERS_START)
    return unless options?
    location.reload() if options.reload
    $(document).trigger @PROC_HANDLERS_START

  _afterProcessHandlers: =>
    options = this.getData(@PROC_HANDLERS_END)
    return unless options?
    $(document).trigger @PROC_HANDLERS_END

  _processHandlers: (handlers, prevStateData, prevRelUrl) =>
    return this._defaultHandler() if handlers.length is 0
    handlers.sort(this._comparePriority)
    stateData = this.getData()

    for i in [0...handlers.length]
      handler = handlers[i]
      data = $.extend({},
        this._getDataComponent(stateData, handler.component),
        {prevRelUrl: prevRelUrl, prevStateData: this._getDataComponent(prevStateData, handler.component)})
      args = [data].concat(handler.args)
      handlers[i].method.apply(handler.context, args)

  _defaultHandler: =>
    # Block scroll from browser trying to load scroll position (saved by browser) from new URL
    @hacks.preventBrowserScroll({blockFirst: true})
    # Reload if state contains listing modal data due to component sharing multiple pages between the same URL.
    # This means changing history states may switch to completely different pages without the browser knowing.
    location.reload() if this.getData(@components.listingModal)?

jQuery ->
  window.HistoryManager = new HistoryManager
