#= require spec_helper
#= require controls/admin/user_typeahead

describe 'Admin.UserTypeahead', ->
  server = null

  beforeEach ->
    $('body').html(JST['templates/controls/admin/user_typeahead']())
    $('#query').adminUserTypeahead(slugInput: $('#slug'))
    server = new MockServer
    server.respondWith(/admin\/users\/typeahead(.*)/, data: {status: 'success', data: {
      matches: [{name: 'Kurt Cobain', email: 'kurt@nirvana.com', slug: 'kurt-cobain'}]
    }})

  afterEach ->
    server.tearDown()

  describe 'entering a query string', ->
    beforeEach ->
      Test.typeChars($('#query'), 'K')
      server.respond()

    it 'shows matching users', ->
      expect($('li.active')).to.have.data('value', 'Kurt Cobain &lt;kurt@nirvana.com&gt;')

    describe 'and selecting a user', ->
      beforeEach ->
        $('li.active a').click()

      it 'fills in the query field', ->
        expect($('#query').val()).to.eq('Kurt Cobain <kurt@nirvana.com>')

      it 'sets the slug', ->
        expect($('#slug').val()).to.eq('kurt-cobain')

      describe 'then clearing the selection', ->
        beforeEach ->
          $('#query').val('').change()

        describe 'and submitting the form', ->
          beforeEach ->
            server.respondWith('/foo', type: 'POST')
            $('button').click()
            server.respond()

          it 'clears the slug', ->
            expect($('#slug').val()).to.eq('')
