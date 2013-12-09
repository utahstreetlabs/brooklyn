jQuery ->
  $('body').on 'click', '[data-source-image]', () ->
    $sourceImage = $(this)
    $('#listing_source_image_id').val($sourceImage.data('source-image'))
    $('[data-source-image]').removeClass('selected')
    $sourceImage.addClass('selected')

  $('body').on 'click', '[data-action=cancel]', () ->
    window.close()
    return false
