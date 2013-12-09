# Component used to make a bootstrap modal scrollable.
#
# By default, the styling and markup used for bootstrap modals do not allow them to be scrollable.
class ScrollableModal
  constructor: (@element) ->
    @element.addClass('scrollable-modal')
    @wrapper =
      $('<div/>', {class: 'modal-wrapper'}).
        appendTo($(document.body)).
        append(@element)
    
    # The wrapper must be in front of the modal backdrop to be the target of the scroll event.
    # Since bootstrap modals are hidden on clicking the modal backdrop, we hide the modal on wrapper click.
    @wrapper.on 'click', (e) =>
      @element.modal('hide') if e.target is @wrapper[0]

    @element.on 'show', =>
      @wrapper.show()
      $(document.body).addClass('disable-scroll')
    @element.on 'hide', =>
      @wrapper.hide()
      $(document.body).removeClass('disable-scroll')

jQuery ->
  $.fn.scrollableModal = copious.plugin.componentPlugin(ScrollableModal, 'scrollableModal')
