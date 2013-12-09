jQuery ->
  # We disable the button used to generate a shipping label if it's currently disabled.
  $('[data-action=generate-label]').on 'click', ->
    !$(this).hasClass('disabled')
