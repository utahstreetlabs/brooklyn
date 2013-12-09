#= require controls/multi_selector
#= require controls/scrollable

# The second step of the create collection modal flow, where the user optionally selects listings to add to the
# newly-created listing.
#
# Attaches a MultiSelector to the modal so that a (hidden) checkbox is toggled when a listing is selected or
# deselected.
class SaveListingsToCollectionModal
  constructor: (@element) ->
    @element.find('[data-role=modal-content]').multiSelector()
    @element.find('.scrollable').scrollable()

jQuery ->
  # plugin api
  $.fn.saveListingsToCollectionModal = ->
    $(this).each ->
      $element = $(this)
      data = $element.data('saveListingsToCollectionModal')
      unless data?
        $element.data('saveListingsToCollectionModal', (data = new SaveListingsToCollectionModal($element)))

  # data api
  $(document).on 'shown', '#collection-create-listings-modal', ->
    $(this).saveListingsToCollectionModal()
