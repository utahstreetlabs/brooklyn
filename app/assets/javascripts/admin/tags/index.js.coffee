jQuery ->
  $ ->
    $form = $('form#tags')
    $form.datagrid()

    # rewrite merge button's href when the link is clicked to include the selected ids in the query string
    $('[data-action=merge]').on 'click', ->
      $link = $(this)
      $link.attr 'href', $form.datagrid('addToggleParams', $link.attr('href'), 'merge_id[]')

    # rewrite delete all button's href when the link is clicked to include the selected ids in the query string
    $('[data-action=delete_all]').on 'click', ->
      $link = $(this)
      $link.attr 'href', $form.datagrid('addToggleParams', $link.attr('href'), 'id[]')
