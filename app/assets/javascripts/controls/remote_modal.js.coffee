#= require controls/flash
#= require copious/tracking
#= require copious/plugin

# Incorporates a remote JSend form into a Twitter Bootstrap modal. Obsoletes copious/modal_remote_form; please use this
# component in preference and help migrate existing usages of the old one to this.

jQuery ->
  class RemoteModal
    constructor: (@element) ->
      @element.on 'show', =>
        this.onShow()
      @element.on 'click.dismiss.modal', '[data-dismiss=modal]', (event) =>
        this.onDismiss()
      @element.on 'click.save.modal', '[data-save=modal]', (event) =>
        this.onSave()
        false # don't bubble the click or allow the default click handler to proceed
      @element.on 'ajax:before', =>
        this.onSubmit()
      @element.on 'ajax:complete', (event, xhr, status) =>
        this.onSubmitComplete()
      @element.on 'ajax:error', (event, xhr, status, error) =>
        this.onSubmitError status, error
      @element.on 'ajax:success', (event, data, status, xhr) =>
        this.onSubmitSuccess data
      @element.on 'jsend:success', (event, data) =>
        this.onSuccess data
      @element.on 'jsend:fail', (event, data) =>
        this.onFail data
      @element.on 'jsend:error', (event, message, code, data) =>
        this.onError message, code, data

    #
    # Lifecycle event callbacks - separated into their own functions for clarity and to remove dependencies on the xhr
    # and jquery event apis
    #

    onShow: =>
      this.clearWindowAlert()
      this.clearModalAlerts()

    onDismiss: =>
      $(document).trigger 'remotemodal:dismissed'

    onSave: =>
      this.save()

    onSubmit: =>
      this.addSourceInputs() if @element.data('include-source')
      this.showSpinner()
      this.clearModalAlerts()

    onSubmitComplete: =>
      this.removeSourceInputs() if @element.data('include-source')
      this.hideSpinner()
      this.performDeferredUntilSubmitComplete()

    onSubmitError: (status, error) =>
      debug.log "Ajax error [#{status}]: #{error}"
      this.showModalError 'There was an error talking to the server. Please try again.'

    onSubmitSuccess: (data) =>
      switch data.status
        when 'success' then @element.trigger 'jsend:success', [data.data]
        when 'fail' then @element.trigger 'jsend:fail', [data.data]
        when 'error' then @element.trigger 'jsend:error', [data.message, data.code, data.data]
        else debug.log "Unknown JSend status #{data.status}"

    onSuccess: (data) =>
      if data.alert?
        this.showWindowNotice(data.alert)
      if data.message?
        this.showModalSuccess(data.message)
      if data.modal?
        this.deferUntilSubmitComplete () =>
          this.replaceContent(data.modal)
      if data.footer?
        this.deferUntilSubmitComplete () =>
          this.replaceFooter(data.footer)
      if data.followupModal?
        this.deferUntilSubmitComplete () =>
          this.replaceModalWithFollowupModal(data.followupModal)
      if data.redirect?
        this.redirectWindow(data.redirect)
      if data.refresh?
        this.deferUntilSubmitComplete () =>
          this.refreshTargetContent(data.refresh)
      if data.replace?
        this.deferUntilSubmitComplete () =>
          this.refreshTargetContent(data.replace, replace: true, keepOpen: data.keepOpen)
      if data.close?
        this.hideModal()

    onFail: (data) =>
      if data.message?
        this.showModalError(data.message)
      if data.modal?
        this.deferUntilSubmitComplete () =>
          this.replaceContent(data.modal)
      if data.errors? && data.errors.base?
        this.deferUntilSubmitComplete () =>
          this.showModalErrors(data.errors.base)

    onError: (message, code, data) =>
      debug.log("JSend error [#{(code || '-')}]: #{message}")
      this.showModalError('There was an error talking to the server. Please try again.')

    #
    # Utilities
    #

    addSourceInputs: =>
      source = copious.source(@element)
      pageSource = copious.pageSource()
      $('form', @element).
        append($('<input>').attr({type: 'hidden', name: 'source', value: source})).
        append($('<input>').attr({type: 'hidden', name: 'page_source', value: pageSource}))

    removeSourceInputs: =>
      $('form', @element).find('[name=source],[name=page_source]').remove()

    # Form submissions can result in window level alerts and/or modal-level alerts.

    clearWindowAlert: =>
      copious.flash.clear()

    showWindowNotice: (msg) =>
      copious.bootstrapAlert.notice(msg)

    clearModalAlert: (a) =>
      copious.flash.fade(a, => $(a).html('').removeClass().addClass('alert'))

    clearModalAlerts: =>
      $('.alert', @element).each((i, el) =>
        this.clearModalAlert(el)
      )

    showModalError: (msg) =>
      $('.alert', @element).addClass('alert-error').html(msg).show().each((i, el) =>
        copious.flash.afterFlashDuration =>
          # Check class of alert as it may have changed
          this.clearModalAlert(el) unless copious.flash.isStickyAlert(el)
      )

    showModalErrors: (msgs) =>
      #XXX: only shows the first error right now. change that up when we need to show more than 1
      $('.alert', @element).addClass('alert-error').html(msgs[0]).show().each((i, el) =>
        copious.flash.afterFlashDuration =>
          # Check class of alert as it may have changed
          this.clearModalAlert(el) unless copious.flash.isStickyAlert(el)
      )

    showModalSuccess: (msg) =>
      $('.alert', @element).addClass('alert-success').html(msg).show().each((i, el) =>
        copious.flash.afterFlashDuration => this.clearModalAlert(el)
      )

    # Remote content fetches and form submissions show a spinner while in flight.

    showSpinner: =>
      $('.spinner', @element).show()

    hideSpinner: =>
      $('.spinner', @element).hide()

    # When the submit request succeeds or fails, the event handler has the option of setting this variable to a
    # function that gets called by the +onSubmitComplete+ handler. This is necessary since, for unknown reasons, if
    # +onSuccess+ or +onFail+ calls +.html+ on an element (seemingly any element at all), +ajax:complete+ is not
    # triggered. Therefore we allow delaying such processing until the request is complete.

    deferUntilSubmitComplete: (func) =>
      @toDoOnSubmitComplete ||= []
      @toDoOnSubmitComplete.push(func)

    performDeferredUntilSubmitComplete: =>
      func.call() for func in @toDoOnSubmitComplete if @toDoOnSubmitComplete?
      @toDoOnSubmitComplete = null # clear the queue

    # Form submission can have a number of different results based on what's indicated by the server in the response.

    # Causes the window to load a new page (thereby destroying the modal).
    redirectWindow: (location) =>
      window.location = location

    # Causes the element(s) specified by the +data-refresh+ attribute to have their content refreshed. Typically used
    # when the form submission results in a portion of the page being updated.
    refreshTargetContent: (content, options) =>
      options ||= {}
      this.hideModal() unless options.keepOpen
      target = @element.data('refresh')
      if target
        $target = $(target)
        if options.replace
          replaced = $target.replaceWith(content)
          replaced.off() # unbind event listeners on replaced element
          $target = $(target)
        else
          $target.html(content)
        $target.trigger('remotemodal:refresh')
      else
        debug.log("No refresh target found")

    # Re-renders the modal content. Useful mainly if you aren't going to close the modal, eg when the form submission
    # fails and the user needs to fix problems.
    replaceContent: (content) =>
      $('[data-role=modal-content]', @element).html(content)
      @element.trigger 'remotemodal:render'

    # Re-renders the modal footer. Useful mostly in combination with #replaceContent to replace the existing footer
    # buttons with new ones.
    replaceFooter: (footer) =>
      $('.modal-footer', @element).html(footer)

    # Hides the existing modal and replaces it on screen with a brand new modal. Useful when you want to show a
    # success message in a new modal in response to an action taken in the original modal, preserving the content of
    # the original modal so that it can be reused.
    replaceModalWithFollowupModal: (followupModalHtml) =>
      this.hideModal()
      # adds the new modal to the DOM and then removes it once it has been dismissed
      $followupModal = $(followupModalHtml)
      # because the new modal is created programatically we have to manually set it up as a remote modal
      if $followupModal.hasClass('remotemodal')
        $followupModal.remotemodal()
      $followupModal.on 'hidden', ->
        $followupModal.remove()
        $(document).trigger 'remotemodal:followupHidden'
      $followupModal.on 'shown', (e) ->
        $(document).trigger 'remotemodal:followupShown'
      $followupModal.modal('show')

    # Hides the modal.
    hideModal: =>
      @element.modal 'hide'

    # Public API

    # Submits the modal's form.
    save: =>
      $forms = $('form', @element)
      $primaryForms = $forms.filter('[data-primary]')
      if $primaryForms.exists()
        $primaryForms.submit()
      else
        $forms.submit()

  # Plugin definition
  $.fn.remotemodal = copious.plugin.componentPlugin(RemoteModal, 'remotemodal')

  # Data API
  $(document).on 'show', '.remotemodal', (e) ->
    $(this).remotemodal()
