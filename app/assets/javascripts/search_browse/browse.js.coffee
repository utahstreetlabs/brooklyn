#= require jquery.dotdotdot
#= require copious
#= require controls/infinite_scroll_manager
#= require copious/search_results
#= require copious/jsend
#= require copious/tracking

jQuery ->
  class Searcher
    constructor: ->
      _.extend(this, Backbone.Events)

    load: (url) -> $.jsend.get(url, facets: true).then((data) => this.trigger('searcher:results:updated', data))

  class Facet
    constructor: (attribute, selector, listSelector = null) ->
      _.extend(this, Backbone.Events)
      @attribute = attribute
      @container = $(selector)
      @tab = @container.closest('.browse-tab')
      @toggle = @container.find('.dropdown-toggle')
      @title = @container.find('[data-role=dropdown-title]')
      @list = if listSelector? then @container.find(listSelector) else @container

      @trackType = @tab.data('tracking')
      @loading_image = '
        <div class="spinner-loading" data-role="spinner">
          <div class="circleG circleG_1"></div>
          <div class="circleG circleG_2"></div>
          <div class="circleG circleG_3"></div>
        </div>'
      @caret = $('<b class="caret"></b>')

      @container.on 'click', "[data-role='facet-change']", (event) =>
        event.preventDefault()
        return unless this._allowFacetChange($(event.target))
        event.stopPropagation() if @toggle.exists()

        closestLink = $(event.target).closest('a')
        existingSpinner = closestLink.find('[data-role=spinner]')
        if not existingSpinner.exists() && closestLink.data('action') != 'remove'
          closestLink.append(@loading_image)

        this._trackClick($(event.currentTarget))
        this.trigger('facet:changed', { event: event, url: closestLink.attr('href') })

    update: (data) =>
      options = data[@attribute]
      @list.empty()
      @list.append(($(o) for o in options)...) if options.length
      if @toggle.exists()
        @title.text(data.titles[@attribute]).append(@caret)
        if @tab.hasClass('open')
          @toggle.dropdown('toggle') unless this instanceof MultiSelectFacet
      else
        if options.length then @container.show() else @container.hide()

    _allowFacetChange: ($target) =>
        this instanceof MultiSelectFacet or not $target.closest('li').hasClass('selected')

    _trackClick: ($target) =>
      # Cannot use copious.track_links because it uses mixpanel.track_links, which redirects after tracking instead
      # of continuing the click event. This reloads the page instead of only firing an async request.
      props = {}
      props[@trackType] = $target.data('title') || $target.text()
      copious.track("#{@trackType} click", props)


  class MultiSelectFacet extends Facet
    constructor: (attribute, selector, listSelector = 'ul') ->
      super(attribute, selector, listSelector)
      @container.on 'change', "[data-role='facet-checkbox']", (event) =>
        this.trigger('facet:changed', { event: event, url: event.target.dataset.url })


  class SelectionFacet extends Facet
    filter: "[data-role='facet-selection']"

    constructor: (selector) ->
      super('selections', selector, @filter)

    update: (data) ->
      @list.remove()
      @container.append(($(s) for s in data[@attribute])...)
      @list = @container.find(@filter)


  class SearchRenderer
    constructor: (searcher, scrollManager, selectors, facets) ->
      { title, count, cards } = selectors

      @searcher = searcher
      @title = $(title)
      @count = $(count)
      @cards = $(cards)
      @facets = facets
      @selection = $('#selection-container')
      @scrollManager = scrollManager

      @searcher.on 'searcher:results:updated', (data) =>
        @title.html(data.title)
        @count.html(data.count)
        this.insertCards(data.cards)
        if data.selections.length > 0 then @selection.show() else @selection.hide() if $('.browse-tab').exists()
        _.each @facets, (facet) -> facet.update(data)
        scrollManager.moreUrl = data.more

      scrollManager.on 'scroller:more', (data) =>
        this.insertCards(data.cards, false, data.offset)

      unless HistoryManager? and HistoryManager.enabled()
        _.each(@facets, (facet) =>
          facet.on('facet:changed', (data) => @searcher.load(data.url)))
      else
        this.setupHistory()

    setupHistory: ->
      _.each @facets, (facet) =>
        facet.on 'facet:changed', (data) =>
          # Do nothing if event was not triggered by a search facet
          return unless $(data.event.target).closest('[data-role=search-facet]').exists()

          stateData = {action: 'insert', url: data.url}
          HistoryManager.addData(HistoryManager.components.searchFacet, stateData, {newEntry: true})

          # Disable the default click action as the search is handled by HistoryManager through the handler
          false

      stateData = {action: 'update', url: document.URL}
      HistoryManager.addData(HistoryManager.components.searchFacet, stateData)
      HistoryManager.addStateHandler(this, HistoryManager.components.searchFacet, this._searchFacetHistoryHandler)

    insertCards: (cards, top = true, offset = null) =>
      $elements = ($(c) for c in cards)
      if top
        @cards.prepend($elements...)
        @cards.children().slice($elements.length).remove()
      else
        @cards.append($elements...)
      _.each $elements, ($element) -> $element.find('.ellipsis').dotdotdot()
      # Disable the line below for now due to a browser loading issue that causes it to load
      # its own saved position after we load our content and perform our own scroll:
      # http://stackoverflow.com/a/12045150/1405830
      # https://bugzilla.mozilla.org/show_bug.cgi?id=679458
#     $('html, body').scrollTop(offset) if offset?

    _searchFacetHistoryHandler: (data) ->
      # prevStateData exists if the previous state's page contained search facets
      return unless data? and data.url? and data.prevStateData?
      relUrl = $.url.parse(data.url).relative
      @searcher.load(data.url) unless relUrl is data.prevRelUrl

########
# MAIN #
########

  window.Copious ?= {}
  window.Copious.initBrowse = ->
    $loadingContainer = $('#loading-container')
    manager = new Copious.InfiniteScrollManager('.search-results', '#scroll-top')
    searcher = new Searcher()
    renderer = new SearchRenderer(searcher, manager, {
      title: '#title-container',
      cards: '.search-results',
      count: '#items-found-number'
    }, [
      new Facet('categories', '#category-container', 'ul'),
      new Facet('tags', '#tag-container', 'ul'),
      new MultiSelectFacet('prices', '#price-container'),
      new MultiSelectFacet('sizes', '#size-container'),
      new MultiSelectFacet('brands', '#brand-container'),
      new MultiSelectFacet('conditions', '#condition-container'),
      new SelectionFacet('#selection-container'),
      new Facet('sorts', '#sort-container', 'ul')
    ])
    manager.on 'scroller:loading:start', -> $loadingContainer.show()
    manager.on 'scroller:loading:end', -> $loadingContainer.hide()
    manager.start()

  Copious.initBrowse()
