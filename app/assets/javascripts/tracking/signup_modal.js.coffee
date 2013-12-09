jQuery ->
  $(document).on 'show', '#signup-modal', (e) ->
    copious.track('signup_modal view', source: this)

  $(document).on 'click', '#signup-modal [data-action=auth-facebook]', (e) ->
    copious.track('signup_modal click', source: this, network: 'facebook')

  $(document).on 'click', '#signup-modal [data-action=auth-twitter]', (e) ->
    copious.track('signup_modal click', source: this, network: 'twitter')

