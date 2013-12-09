jQuery ->
  # select the corresponding main photo when a thumbnail is clicked
  $mainPhotos = $('#listing-photos img')
  $thumbnails = $('#listing-thumbnails img')
  $thumbnails.on 'click', () ->
    $mainPhotos.hide()
    $newPhoto = $("#photo-#{$(this).data('photo')}")
    $newPhoto.fadeIn()
    $(document).trigger('photo:selected', [$newPhoto])
    false
