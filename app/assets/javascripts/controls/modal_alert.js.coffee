#= require copious/plugin

# A control for alerts in modals
class ModalAlert
  constructor: (@element) ->
    @alert = @element.find('[data-role=alert]')

  info: (message) =>
    @alert.show().addClass('alert-info').html(message)

  error: (message) =>
    @alert.show().addClass('alert-error').html(message)

  clear: =>
    @alert.hide().removeClass().addClass('alert').html('')

jQuery ->
  $.fn.modalAlert = copious.plugin.componentPlugin(ModalAlert, 'modalAlert')

