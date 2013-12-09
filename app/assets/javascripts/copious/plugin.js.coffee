#= require copious

copious.plugin = {}

# Create a jQuery plugin that instantiates a component and
# forwards method calls to it after instantiation.
#
# Given a component:
#
# class DummyComponent
#   foo: (name) ->
#     "hello #{name || 'world'}!"
#
# this function can be used to create a jQuery plugin like this:
#
# $.fn.dummyComponent = copious.plugin.componentPlugin(DummyComponent, 'dummyComponent')
#
# Clients must pass a name to componentPlugin because we cannot reliably
# get the name of the coffeescript at runtime in the face of minification, which
# renames functions. See:
#
# https://github.com/jashkenas/coffee-script/issues/2052
#
# This plugin can be used to set instantiate a new instance of the
# component and return the chainable it was invoked on:
#
# $('#dummy-component').dummyComponent()
#
# It will only ever create a single instance of the component. Subsequent
# invocations of this plugin on the same element will do nothing unless
# additional arguments are passed.
#
# If additional arguments are passed, in addition to instantiating the
# component as needed, the plugin will invoke a method on the component
# and return the result rather than the chainable the plugin was invoked
# on:
#
# $('#dummy-component').dummyComponent('foo')
# => 'hello world!'
#
# Additional arguments will be passed to the component:
#
# $('#dummy-component').dummyComponent('foo', 'new pope')
# => 'hello new pope!'
#
# The plugin also defines an "instance" method on the component it wraps, so
# that plugin user can easily obtain an instance of the component without
# needing to know the details of the internal storage structure:
#
# $('#dummy-component').dummyComponent('instance')
# => DummyComponent { foo: function }
copious.plugin.componentPlugin = (klazz, dataAttr) ->
  klazz.prototype.instance = ->
    this
  (option) ->
    # convert arguments to an array, thanks http://debuggable.com/posts/turning-javascript-s-arguments-object-into-an-array:4ac50ef8-3bd0-4a2d-8c2e-535ccbdd56cb
    args = Array.prototype.slice.call(arguments)
    lastResult = null
    eachResult = $(this).each ->
      $element = $(this)
      instance = $element.data(dataAttr)
      unless instance?
        options = if typeof option is 'object' then option else {}
        $element.data(dataAttr, (instance = new klazz($element, options)))
      if typeof option is 'string'
        lastResult = instance[option].apply(instance, args[1..])
    lastResult || eachResult

