#= require copious/tracking

class AddCollectionCard
  constructor: (@element) ->
    @button = @element.find('[data-role=add-collection-card-button]')
    @modal = $(@button.data('target'))
    @username = @element.data('user')

  add: =>
    source = copious.source(@button)
    copious.track('add_listing_modal_collection click', username: @username, source: source)
    @modal.data('source', source)

jQuery ->
  # plugin api
  $.fn.addCollectionCard = (option) ->
    $(this).each ->
      $element = $(this)
      data = $element.data('addCollectionCard')
      unless data?
        $element.data('addCollectionCard', (data = new AddCollectionCard($element)))
      if typeof option is 'string'
        data[option].call($element)

  # data api
  $(document).on 'click', '[data-role=add-collection-card-button]', ->
    $(this).closest('[data-role=add-collection-card]').addCollectionCard('add')
