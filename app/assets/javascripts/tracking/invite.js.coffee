jQuery ->
  $(document).on 'inviteModal:invite', '[data-role=invite-modal]', (e, data) ->
    $modal = $(this)
    copious.track('invite_modal click', {source: this, share_channel: 'facebook_request', selected_recipients: data.recipients.length})
