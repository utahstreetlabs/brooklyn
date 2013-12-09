#= require copious/tracking
#= require copious/jsend
#= require copious/plugin
#= require controls/modal_alert
#= require controls/modal_spinner
#= require controls/scrollable

# A control for lazily loading modal dialog content.
#
# Modal controls should instantiate a ModalLoader and manually call load().
# load() will return a Deferred that can be chained to run code after content loads:
#
#   @loader = new ModalLoader(@element)
#   @loader.load().then =>
#     this._initContent()
#
class ModalLoader
  @_LOAD_ERROR: """
Oops, something's not right. <a href="javascript:location.reload()">Click here to reload</a>.
"""

  constructor: (@element) ->
    @url = @element.data('url')
    @source = @element.data('source')
    @content = @element.find('[data-role=modal-content]')
    @alert = @element.find('[data-role=alert]')
    @loadDeferred = null

  load: =>
    @loadDeferred ||= this._fetchContent()

  spinnerOn: =>
    @element.modalSpinner('on')

  spinnerOff: =>
    @element.modalSpinner('off')

  showModalError: () =>
    @element.modalAlert('error', ModalLoader._LOAD_ERROR)

  _fetchContent: =>
    options = {
      beforeSend: this.spinnerOn,
      complete: this.spinnerOff
    }
    query = {
      source: @source,
      page_source: copious.pageSource()
    }
    $.jsend.get(@url, query, options).
      then((data) =>
        this._initContent(data.modal)
        @loaded = true
        data
      ).
      fail((status, data) =>
        this.showModalError()
        data
      )

  _initContent: (html) =>
    @content.html(html)
    @content.find('.scrollable').scrollable()

jQuery ->
  window.ModalLoader = ModalLoader
  $.fn.modalLoader = copious.plugin.componentPlugin(ModalLoader, 'modalLoader')
  $('[data-loaded-modal]').on 'show', ->
    $(this).modalLoader('load')
