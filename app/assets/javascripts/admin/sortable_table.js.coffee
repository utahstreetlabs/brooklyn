jQuery ->
  $('[data-role=sortable-table] tbody').sortable().disableSelection()

  $('[data-role=sortable-table] tbody').on 'sortupdate', (event, ui) ->
    # Update the order of the items by firing off a reorder ajax request
    $.jsend.post(ui.item.data('reorder-url'), {position: ui.item.parents('tbody').find('tr').index(ui.item)})
