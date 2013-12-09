window.Test ?= {}

window.Test.Keys = {
  ENTER: 13
}

triggerKeyEvent = (name) ->
  (selectorOrObject, key, modifier) ->
    element = if selectorOrObject instanceof jQuery then selectorOrObject else $(selectorOrObject)
    event = jQuery.Event(name)
    event.which = key
    element.trigger(event)

window.Test.triggerKeyDown = triggerKeyEvent('keydown')
window.Test.triggerKeyPress = triggerKeyEvent('keypress')
window.Test.triggerKeyUp = triggerKeyEvent('keyup')
