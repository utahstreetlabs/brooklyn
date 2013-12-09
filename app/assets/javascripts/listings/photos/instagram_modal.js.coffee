# Provides helper functionality for a modal that displays instagram
# images to import
#
# Requires jquery.endless-scroll to be loaded

jQuery ->

  $('#instagram-modal').each ->
    $modal = $(this)
    $modalBody = $modal.find('.modal-body')

    $modal.off 'jsend:success'

    fired = false

    $modal.on 'show', ->
      $modalBody.empty()
      $modalBody.endlessScroll(
        bottomPixels: 50
        fireOnce: true
        fireDelay: 500
        callback: =>
          $more = $('.instagram-photos-more')
          $spinner = $('.loading-overlay-holder')
          if fired != true
            fired = true
            $spinner.show()
            $.ajax
              url: $more.attr('href')
              dataType: 'json'
              success: (json) ->
                last_img = $("ul#instagram-photos li:last")
                $.each json.data['results'], (j,item) ->
                  last_img.after($(item.ui))
                  last_img = $("ul#instagram-photos li:last")
                $more.attr('href',json.data['more'])
                fired = false
                $spinner.hide()
       )
