#= require controls/scrollable

trackInviteModalView = (type) -> copious.track('send invites view', {invite_type: type})

jQuery ->
  $("[data-invite=facebook]").on "click", (e) ->
    e.preventDefault()
    $('#invited-modal').modal('hide')
    $('#invite_friends_via_facebook-modal').modal('show')
    $('#invite_friends_via_facebook-modal .modal-body').scrollable()
    trackInviteModalView('facebook')

  $("[data-invite=email]").on "click", (e) ->
    e.preventDefault()
    $('#invited-modal').modal('hide')
    $('#invite_friends_via_email-modal').modal('show')
    trackInviteModalView('email')

  # if the invited modal is present, it should be shown automatically
  $('#invited-modal').modal('show')

  $("a.share").click (e) ->
    e.preventDefault()
    invite = window.open(@href, "shares-section", "height=450,width=550")
    invite.focus()  if window.focus
    $(document).trigger "shareClicked"
