jQuery ->
  $.widget "copious.searchboxwidget",
    options:
      change: ->

    _init: ->
      @element.bind "searchboxwidgetchange", @options.change
      @searchInput = $("input[name='search']", @element)
      @clearButton = $("a.search_clear", @element)
      @searchButton = $("#searchButton", @element)
      @searchForm = $("#search_listings")

      this.showClearIfNeeded()

      onchange = ($event) =>
        this.showClearIfNeeded()

      @searchInput.change(onchange).keydown(onchange)

      @clearButton.click ($event) ->
        this.clearContent()

      @searchInput.on "focus", =>
        @searchButton.show() if @searchButton.is(":hidden")

      @searchInput.on "blur", =>
        @searchButton.fadeOut() unless @searchButton.is(":hidden")

      @searchForm.on "submit", ->
        $('#search_box #spinner_loading').show()

    clearContent: ->
      @searchInput.val ""
      this.showClearIfNeeded()

    showClearIfNeeded: ->
      @clearButton.toggleClass "clear_on", !!@searchInput.val()
