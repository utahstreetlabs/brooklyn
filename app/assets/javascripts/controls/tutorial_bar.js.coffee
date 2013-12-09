# requires facebook js library

jQuery ->
  $tutorialBar = $('[data-role=tutorial-bar]')

  updateSuggestion = ->
    $incompleteSteps = $('[data-role=tutorial-step]:not(.complete)')
    if $incompleteSteps.length == 0
      $tutorialBar.hide()
      # we need to manage a class on the parent thanks to bootstrap's affix
      # plugin:  http://twitter.github.com/bootstrap/javascript.html#affix
      $tutorialBar.parent().removeClass('contains-tutorial-bar')
    else
      $incompleteSteps.first().addClass('suggestion')

  $tutorialBar.on 'click', '[data-action=invite-cta]', (e) ->
    e.preventDefault()
    copious.track('invite_btn click', {source: this, share_channel: 'facebook_request'})
    # XXX: should post to feed/tutorial_bar/invite_requests_controller
    $this = $(this)
    new Copious.InviteModal $($this.data('target')),
      source: 'tutorial_bar',
      afterInvited: () =>
        $this.closest('[data-role=tutorial-step]').addClass('complete').removeClass('suggestion')
        updateSuggestion()

  $(document).on 'loveButton:loved', ->
    $('[data-tutorial-action=like]').addClass('complete').removeClass('suggestion')
    updateSuggestion()

  $(document).on 'listing:commented', ->
    $('[data-tutorial-action=comment]').addClass('complete').removeClass('suggestion')
    updateSuggestion()
