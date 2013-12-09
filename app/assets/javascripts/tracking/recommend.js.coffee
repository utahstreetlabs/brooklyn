jQuery ->
  $(document).on 'click', '[data-action=recommend-cta]', (e) ->
    $button = $(this)
    copious.track('recommend_modal view', {source: this, share_channel: 'facebook_request'})

  $(document).on 'inviteModal:invite', '[data-role=recommend-modal]', (e, data) ->
    $modal = $(this)
    copious.track('recommend_modal click', {source: this, share_channel: 'facebook_request', selected_recipients: data.recipients.length})

  $(document).on 'inviteModal:requestSent', '[data-role=recommend-modal]', (e, data) ->
    $modal = $(this)
    copious.track('fb_request sent', {source: this, request_type: 'u2u_recommend'})

  $(document).on 'inviteModal:requestCancelled', '[data-role=recommend-modal]', (e, data) ->
    $modal = $(this)
    copious.track('fb_request cancel', {source: this, request_type: 'u2u_recommend'})
