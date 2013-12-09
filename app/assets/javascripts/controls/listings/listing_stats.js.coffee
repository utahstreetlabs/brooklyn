jQuery ->
  $(document).on 'listingStats:replaced', (e, listingId, html) ->
    $(document).find("[data-listing=#{listingId}] [data-role=listing-stats]").replaceWith(html)
