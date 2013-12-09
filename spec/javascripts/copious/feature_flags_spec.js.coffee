#= require spec_helper
#= require copious/feature_flags

describe 'copious/feature_flags', ->
  beforeEach ->
    $('head').html(JST['templates/copious/feature_flags']())

  describe 'featureEnabled', ->
    it 'returns true if there is an enabled meta tag', ->
      expect(copious.featureEnabled('test.enabled_feature')).to.be.true
    it 'returns false if there is an disabled meta tag', ->
      expect(copious.featureEnabled('test.disabled_feature')).to.be.false
    it 'returns false if there is an no meta tag', ->
      expect(copious.featureEnabled('test.not_a_feature')).to.be.false

