# XXX: rewrite datagrid component to support form submission via external links

# Sets up an external button for each element that matches +selector+. When an external button is clicked, it is
# put into the loading state, and +$form+ is submitted to the button's +href+ attribute using the method specified
# by the button's +data-method+ attribute.
externalButton = ($form, selector) ->
  $button = $(selector)
  $button.on 'click', ->
    $button.button('loading')
    $form.attr('action', $button.attr('href'))
    $form.append("<input name=\"_method\" value=\"#{$button.data('method')}\" type=\"hidden\"/>")
    $form.submit()
    false
  $button

jQuery ->
  $interestsForm = $('form#interests')
  $interestsForm.datagrid()

  externalButton($interestsForm, '[data-action=add_all_to_onboarding]')
  externalButton($interestsForm, '[data-action=remove_all_from_onboarding]')
  externalButton($interestsForm, '[data-action=destroy_all]')
