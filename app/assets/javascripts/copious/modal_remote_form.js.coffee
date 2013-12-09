# Incorporates a remote JSend form into a Twitter Bootstrap modal.
#
#= require copious/remote_form
#= require controls/flash

jQuery ->
  fetchRemoteContent = ($modal) ->

    $modalBody = $modal.find('.modal-body')
    $.ajax
      url: $modal.data('content-url')
      dataType: 'html'
      beforeSend: ->
        $('.spinner', $modal).show()
      success: (data) ->
        $('.spinner', $modal).hide()
        if data
          $modalBody.html(data).show()
      fail: (data) ->
        $('.spinner', $modal).hide()
        $modal.modal 'hide'

  $('.modal:not(.remotemodal)').each ->
    $modal = $(this)
    # since we are initializing these modals at document ready rather than when a trigger is clicked, we need to
    # explicitly hide them
    $modal.modal(show: false)

    $.remoteForm.initRemoteForm $modal

    $modal.on 'show', ->
      copious.flash.clear()
      $('.alert', $modal).hide().html('').removeClass().addClass('alert')
      if $modal.data('content-url')
        fetchRemoteContent($modal)

    $modal.on 'click', '[data-save=modal]', ->
      $('form', $modal).trigger 'submit'

    $modal.on 'ajax:before', ->
      $('.spinner', $modal).show()
      $('.alert', $modal).hide().html('').removeClass().addClass('alert')

    # XXX: why is this event not being triggered?
    $modal.on 'ajax:complete', ->
      $('.spinner', $modal).hide()

    $('form', $modal).off 'ajax:error', $.remoteForm.showFlashOnAjaxError
    $modal.on 'ajax:error', (event, xhr, status, error )->
      debug.log "Ajax error [#{status}]: #{error}"
      $('.alert', $modal).addClass('alert-error').html('There was an error talking to the server. Please try again.').
        show()

    $('form', $modal).off 'jsend:success', $.remoteForm.showFlashOnSuccess
    $modal.on 'jsend:success', (event, data) ->
      $('.spinner', $modal).hide() # XXX
      if data.alert
        copious.bootstrapAlert.notice(data.alert)
      if data.message
        $('.alert', $modal).addClass('alert-success').html(data.message).show()
      if data.redirect
        window.location = data.redirect
      if data.refresh
        $modal.modal 'hide'
        $($modal.data('refresh')).html data.refresh

    $('form', $modal).off 'jsend:fail'
    $modal.on 'jsend:fail', (event, data) ->
      $('.spinner', $modal).hide() # XXX
      if data.message
        $('.alert', $modal).addClass('alert-error').html(data.message).show()
      if data.modal
        $('[data-role=modal-content]').html data.modal
        $.remoteForm.initRemoteForm $modal

    $('form', $modal).off 'jsend:error', $.remoteForm.showFlashOnJsendError
    $modal.on 'jsend:error', (event, message, code, data) ->
      $('.spinner', $modal).hide() # XXX
      debug.log "JSend error [#{(code || '-')}]: #{message}"
      $('.alert', $modal).addClass('alert-error').html('There was an error talking to the server. Please try again.').
        show()
