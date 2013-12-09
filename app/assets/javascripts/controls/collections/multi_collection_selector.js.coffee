#= require copious/plugin
#= require controls/multi_selector
#= require controls/collections/new_collection_input

# A class that ties together events from MultiSelector with the have/want
# semantics of CollectionModal.
#
# Calls multiSelector on the element it is passed so that clients can just
# use this plugin.
#
# Events:
#
# +collection:wantSelected+ triggered when a user selects a "want" collection
# +collection:wantUnselected+ triggered when a user unselects a "want" collection
# +collection:haveSelected+ triggered when a user selects a "have" collection
# +collection:haveUnselected+ triggered when a user unselects a "have" collection
#
class MultiCollectionSelector
  constructor: (@element) ->
    $multiSelector = $('[data-role=multi-selector]', @element).multiSelector()
    $multiSelector.on 'selectable:selected', (e, selectable) =>
      collectionType = $(selectable.element).data('collection-type')
      if collectionType == 'have'
        @element.trigger('collection:haveSelected')
      else if collectionType == 'want'
        @element.trigger('collection:wantSelected')

    $multiSelector.on 'selectable:unselected', (e, selectable) =>
      collectionType = $(selectable.element).data('collection-type')
      if collectionType == 'have'
        @element.trigger('collection:haveUnselected')
      else if collectionType == 'want'
        @element.trigger('collection:wantUnselected')

    $newCollectionInput = $('[data-role=name-input]', @element).newCollectionInput()
    $newCollectionInput.on 'newCollectionInput:created', (e, data) =>
      $multiSelector.multiSelector('prependSelectable', $(data.selectable))


jQuery ->
  $.fn.multiCollectionSelector = copious.plugin.componentPlugin(MultiCollectionSelector, 'multiCollectionSelector')
  $('[data-role=multi-collection-selector]').multiCollectionSelector()