jQuery ->
  $('body').on 'remotelink:refresh', '[data-role=flag-enabled]', () ->
    $(this).find('[data-action]').each ->
      $.remoteLink.initRemoteLink(this)
