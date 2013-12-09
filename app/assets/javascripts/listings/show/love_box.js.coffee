jQuery ->
  # update the love box after the listing is loved or unloved
  $(document).on "loveButton:loved", (event, data) =>
    if data.love_box
      $('#love-box-facepile').replaceWith(data.love_box)
