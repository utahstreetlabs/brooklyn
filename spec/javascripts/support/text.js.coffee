#= require copious

window.Test ?= {}

window.Test.typeChar = (input, char, options = {}) ->
  keycode = if typeof char is 'string'
    char.charCodeAt(0)
  else if typeof char is 'number'
    char
  else
    null
  return if keycode is null

  setValueAfterChange = options.setValueAfterChange

  current = input.val()
  Test.triggerKeyDown(input, keycode)
  Test.triggerKeyPress(input, keycode)
  # Assume default action of event has been triggered iff the input value has not changed
  if setValueAfterChange or current is input.val()
    caretPos = Test.getCaretPos(input)
    current = input.val()
    input.val(COPIOUS.util.strSplice(current, String.fromCharCode(keycode), caretPos))
    Test.setCaretPos(input, caretPos + 1)
  Test.triggerKeyUp(input, keycode)

window.Test.typeChars = (input, str, options) ->
  return unless typeof str is 'string'
  Test.typeChar(input, char, options) for char in str.split('')

window.Test.typeSpecial = (input, keycode, options = {}) ->
  return Test.typeBackspace(input) if keycode is KEYCODE_BACKSPACE
  Test.triggerKeyDown(input, keycode)
  # Some browsers (e.g. FF) fire keypress events on special key presses.
  # Use triggerKeyPress option to test for cross-browser consistency.
  Test.triggerKeyPress(input, 0) if options.triggerKeyPress
  Test.triggerKeyUp(input, keycode)

window.Test.typeBackspace = (input, options = {}) ->
  caretPos = Test.getCaretPos(input)
  current = input.val()
  Test.triggerKeyDown(input, KEYCODE_BACKSPACE)
  Test.triggerKeyPress(input, 0) if options.triggerKeyPress
  input.val(COPIOUS.util.strReplaceAt(current, '', caretPos - 1))
  Test.setCaretPos(input, caretPos - 1)
  Test.triggerKeyUp(input, KEYCODE_BACKSPACE)

window.Test.getCaretPos = (input) ->
  textbox = input.get(0)
  return if textbox.selectionStart?
    textbox.selectionStart
  else if document.selection?
    input.focus()
    sel = document.selection.createRange()
    selLength = document.selection.createRange().text.length
    sel.moveStart 'character', -input.val().length
    sel.text.length - selLength
  else
    0

window.Test.setCaretPos = (input, newPos) ->
  textbox = input.get(0)
  if textbox.selectionStart?
    textbox.setSelectionRange(newPos, newPos)
    true
  else if textbox.createTextRange?
    # XXX: apparently this is supported in almost no browsers.  should we be using createRange?
    range = textbox.createTextRange()
    range.move('character', newPos)
    range.select()
    true
  else
    false
