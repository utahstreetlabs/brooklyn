# Scroll the page down 1px on page load to remove the browser chrome on mobile devices.
jQuery ($) ->
  $body = $(document.body)
  $body.scrollTop(1) if $body.scrollTop() is 0
