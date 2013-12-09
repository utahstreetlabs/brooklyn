#= require spec_helper
#= require controls/multi_selector

describe 'MultiSelector', ->
  describe 'with an external select-all control', ->
    beforeEach ->
      $('body').html(JST['templates/controls/multi_selector/external_select_all']())
      $('#selector').multiSelector(selectAll: $('#select-all'))

    it 'selects all', ->
      $('#select-all').prop('checked', true).change()
      expect($('#selector').multiSelector('instance').anySelected()).to.be.true

    it 'unselects all', ->
      $('#select-all').prop('checked', false).change()
      expect($('#selector').multiSelector('instance').anySelected()).to.be.false

  describe 'with an internal select-all control', ->
    beforeEach ->
      $('body').html(JST['templates/controls/multi_selector/internal_select_all']())
      $('#selector').multiSelector()

    it 'selects all', ->
      $('#select-all').prop('checked', true).change()
      expect($('#selector').multiSelector('instance').anySelected()).to.be.true

    it 'unselects all', ->
      $('#select-all').prop('checked', false).change()
      expect($('#selector').multiSelector('instance').anySelected()).to.be.false
