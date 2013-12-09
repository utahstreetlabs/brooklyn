#= require 'copious/plugin'

class ModalSpinner
  constructor: (@element) ->
    @spinner = @element.find('[data-role=spinner]')

  on: =>
    @spinner.show()

  off: =>
    @spinner.hide()

jQuery ->
  $.fn.modalSpinner = copious.plugin.componentPlugin(ModalSpinner, 'modalSpinner')
