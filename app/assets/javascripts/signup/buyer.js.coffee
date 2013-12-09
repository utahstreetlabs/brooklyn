jQuery ->
  # Likes
  $counter = $(".like-button-container").likesCounter(requiredCount: $(".like-button-container").attr('data-required'))

  #TODO: Rename these to interests when the tag switchover is complete. -Cory Aug 17, 2012
  $(document).on 'interestCard:liked', ->
    $counter.likesCounter "update", true

  $(document).on 'interestCard:unliked', ->
    $counter.likesCounter "update", false

  #Add check for like count.  Prevent click, if user hasn't liked enough.
  $('.likes-counter-button').on 'click', (e) -> !$(this).hasClass('disabled')

  #Browser specific code here as a fallback as IE does not support CSS pointer-events.
  if ($.browser.msie)
    $(".interest-overlay, .interest-state").on "click", ->
      $(this).parent().find('a').click()
