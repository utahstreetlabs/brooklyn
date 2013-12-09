jQuery ->
  promotionData = (element) ->
    $element = $(element)
    { username: $element.data('user'), promotion: $element.data('promotion') }

  copious.track_links ".promotion-link", 'promotion_card click', (link) ->
    $.extend(promotionData($(link).closest('[data-role=promotion-card]')), clicked_at: (new Date()).toString())

  $('[data-role=promotion-card]').each (i, card) ->
    copious.track('promotion_card view', $.extend(promotionData(card), viewed_at: (new Date()).toString()))

