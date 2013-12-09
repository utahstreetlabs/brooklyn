#= require 'copious/plugin'
#= require 'copious/remote_link'

class InterestCard
  constructor: (@element) ->

  toggle: () =>
    $likeLink = @element.find('[data-toggle=interest-like]')
    $.jsend.ajax($likeLink.data('target'), {}, $likeLink.data('method')).
      then((data) =>
        this._updateCard(data)
        $likeLink.replaceWith(data.button))

  _updateCard: (data) =>
    if data.liked
      @element.trigger('interestCard:liked', data)
      @element.addClass('liked')
    else
      @element.trigger('interestCard:unliked', data)
      @element.removeClass('liked')

jQuery ->
  $.fn.interestCard = copious.plugin.componentPlugin(InterestCard, 'interestCard')
  $(document).on 'click', '[data-toggle=interest-like]', (e) ->
    $(this).closest('[data-role=interest-card]').interestCard('toggle')
