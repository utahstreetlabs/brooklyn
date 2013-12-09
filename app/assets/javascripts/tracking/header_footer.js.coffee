jQuery ->
  $(document).on 'click', '.home-header [data-action=auth-facebook]', (e) ->
    copious.track('signup_header click', network: 'facebook')

  $(document).on 'click', '.home-header [data-action=auth-twitter]', (e) ->
    copious.track('signup_header click', network: 'twitter')
