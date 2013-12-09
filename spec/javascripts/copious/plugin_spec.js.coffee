#= require spec_helper
#= require copious/plugin

constructorSpy = sinon.spy()
fooSpy = sinon.spy()

class DummyComponent
  constructor: ->
    constructorSpy.apply(this, arguments)

  foo: ->
    fooSpy.apply(this, arguments)

$.fn.dummyComponent = copious.plugin.componentPlugin(DummyComponent, 'dummyComponent')

describe 'copious/plugin', ->
  $element = null
  beforeEach ->
    $('body').html(JST['templates/copious/plugin']())
    $element = $('#dummy-component')

  afterEach ->
    constructorSpy.reset()
    fooSpy.reset()

  describe 'plugin method created by componentPlugin', ->
    it 'is only initialized once', ->
      $element.dummyComponent()
      $element.dummyComponent()
      expect(constructorSpy).to.have.been.called.once

    it 'returns the jquery $element if called without args', ->
      expect($element.dummyComponent()).to.be($element)

    it 'calls methods on the component when passed a method name', ->
      $element.dummyComponent('foo', 'bar', 1)
      expect(constructorSpy).to.have.been.called.once
      expect(fooSpy).to.have.been.calledWith('bar', 1).once

    it 'passes options to the constructor when passed an object', ->
      $element.dummyComponent(foo: 'bar')
      expect(constructorSpy).to.have.been.calledWith(sinon.match.instanceOf(jQuery), foo: 'bar').once
      expect(fooSpy).to.not.have.been.called

    it 'defines an instance method that returns the component instance', ->
      $element.dummyComponent('instance').foo('buz', 2)
      expect(constructorSpy).to.have.been.called.once
      expect(fooSpy).to.have.been.calledWith('buz', 2).once
