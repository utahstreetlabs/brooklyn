#= require spec_helper
#= require constants
#= require history_manager
#= require controls/listings/listing_modal

# Append history meta tag to enable history support for listing modal
$('head').append($('<meta>', {name: 'copious:ff:history_manager', content: 'enabled'}))

describe 'listings.ListingModal', ->
  # Tests may sometimes cause Chrome to blow up due to modal history support, which does weird things in iframes.
  # In such cases, keep calm, try again, and (╯°□°）╯︵ ┻━┻ if it still doesn't work.
  server = null
  this.timeout(500)

  # use regexps for the modal view requests so they don't catch the comment requests as well and to account for
  # the source and page_source params in the query string

  respondForModalWithSuccess = ->
    server.respondWith(/\/listings\/hamburgler-doll\/modal(?!\/comments)/, data: {status: 'success', data:
                      { modal: """
<div>Hamburgler Doll</div>
<div data-role="listing-modal-top">
  <div data-role="listing-modal-header">
  </div>
  <div data-role="listing-modal-body">
    <div data-role="listing-modal-navigation">
      <a class="carousel-control left" data-slide="prev" data-action="navigate" href="javascript:void(0)">‹</a>
      <a class="carousel-control right" data-slide="next" data-action="navigate" href="javascript:void(0)">›</a>
    </div>
    <div data-role="ctas">
      <div id="like-count">23</div>
      <div id="save-count">5</div>
      <button data-toggle="love">Love</button>
      <button data-toggle="modal" data-target="#listing-save-to-collection-123-modal"
              data-action="save-to-collection-cta">Save</button>
    </div>
    <div data-role="comments">
      <form method="POST" action="/listings/hamburgler-doll/modal/comments" data-remote="true">
        <div class="control-group">
          <div class="controls">
            <textarea name="comment[text]"></textarea>
          </div>
        </div>
      </form>
    </div>
  </div>
</div>
<div data-role="listing-modal-footer">
  <div data-role="listing-modal-thumbnails">
    <ul>
      <li data-role="thumbnail-wrapper"><img id="thumbnail-1" src="ham.jpg" data-index="0" data-role="thumbnail" data-url="/listings/delicious-ham/modal/top"></li>
      <li data-role="thumbnail-wrapper"><img id="thumbnail-2" src="unham.jpg" data-index="1" data-role="thumbnail" data-url="/listings/spoiled-ham/modal/top"></li>
    </ul>
  </div>
</div>"""}})

  respondForModalWithFailure = ->
    server.respondWith(/\/listings\/hamburgler-doll\/modal(?!\/comments)/, data: {status: 'fail', data: {
                       status: 400, error: 'You suck'}})

  respondForModalTopWithSuccess = ->
    server.respondWith(/\/listings\/delicious-ham\/modal\/top/, data: {status: 'success', data:
                      { modalTop: """
<div>Delicious Ham</div>
"""}})

  respondForModalTopWithFailure = ->
    server.respondWith(/\/listings\/hamburgler-doll\/modal\/top/, data: {status: 'fail', data: {
                       status: 400, error: 'You suck'}})

  respondForCommentsWithSuccess = (comments) ->
    str = ''
    str += "<li>#{c}</li>" for c in comments
    server.respondWith('/listings/hamburgler-doll/modal/comments', type: 'POST', data: {
                       status: 'success', data: { comment: """
<div data-role="comments">
  <ul data-role="comment-stream">#{str}</ul>
  <form method="post" action="/listings/hamburgler-doll/modal/comments" data-remote="true">
    <textarea name="comments[text]"></textarea>
  </form>
</div>"""}})

  respondForCommentsWithError = ->
    server.respondWith('/listings/hamburgler-doll/modal/comments', type: 'POST', data: {
                       status: 'fail', data: { errors: { text: ['This field is required.']}}})

  isBrowserFF = navigator.userAgent.toLowerCase().indexOf('firefox') > -1

  beforeEach ->
    $('body').html(JST['templates/controls/listings/listing_modal']())
    server = new MockServer

  afterEach ->
    server.tearDown()

  describe 'clicking on the toggle', ->
    beforeEach ->
      $('#toggle').click()

    it 'instantiates a ListingModal', ->
      expect($('#listing-123-modal').data('listingModal')).to.be

    it 'shows a scrollable modal', (done) ->
      respondForModalWithSuccess()
      server.respond()
      setTimeout( ->
        expect($('#listing-123-modal')).to.be.visible
        expect($('#listing-123-modal').data('scrollableModal')?).to.be.true
        done()
      , 100)

    it 'disables background scroll', ->
      respondForModalWithSuccess()
      server.respond()
      expect($(document.body)).to.have.class('disable-scroll')

    it 'loads the content successfully', ->
      respondForModalWithSuccess()
      server.respond()
      expect($('#listing-123-modal')).to.contain('Hamburgler Doll')

    it 'shows an error when loading the content fails', ->
      respondForModalWithFailure()
      server.respond()
      expect($('#listing-123-modal')).to.contain('Oops')

    it 'updates the URL to the listing URL', ->
      respondForModalWithSuccess()
      server.respond()
      expect(document.URL).to.equal($('#toggle').prop('href'))

    describe 'then scrolling down', ->
      beforeEach ->
        $('.modal').css({
          height: '3000px',
          'max-height': '3000px'
        })

      it 'does not scroll the background', ->
        $('body').scrollTop(1000)
        expect($('body').scrollTop()).to.equal(0)

      it 'scrolls the modal', ->
        $('.modal-wrapper').scrollTop(1000)
        expect($('.modal-wrapper').first().scrollTop()).to.not.equal(0)

    describe 'then clicking outside the toggle', ->
      beforeEach ->
        $('.modal-backdrop').click()

      it 'hides the modal', ->
        expect($('#listing-123-modal')).to.be.hidden

      it 'enables background scroll', ->
        respondForModalWithSuccess()
        server.respond()
        expect($(document.body)).to.not.have.class('disable-scroll')

      describe 'then clicking it one more time', ->
        beforeEach ->
          $('#toggle').click()

        it 'shows the modal again', (done) ->
          respondForModalWithSuccess()
          server.respond()
          setTimeout( ->
            expect($('#listing-123-modal')).to.be.visible
            done()
          , 100)

        it 'does not create a new modal', ->
          expect($('#listing-123-modal').length).to.equal(1)

    describe 'then pressing the esc key', ->
      beforeEach ->
        Test.typeSpecial($('#listing-123-modal'), KEYCODE_ESC)

      it 'hides the modal', ->
        expect($('#listing-123-modal')).to.be.hidden

      describe 'then clicking it one more time', ->
        beforeEach ->
          $('#toggle').click()

        it 'shows the modal again', (done) ->
          respondForModalWithSuccess()
          server.respond()
          setTimeout( ->
            expect($('#listing-123-modal')).to.be.visible
            done()
          , 100)

        it 'does not create a new modal', ->
          expect($('#listing-123-modal').length).to.equal(1)

    describe 'then going back in the browser', ->
      # These cases may fail sometimes in Chrome due to timing and incorrectly checking modal visibility
      # Visually inspecting the test cases however confirms that the tests pass, even if it fails in Konacha
      this.timeout(300)
      beforeEach ->
        history.back() if history

      it 'hides the modal', (done) ->
        setTimeout( ->
          expect($('#listing-123-modal')).to.be.hidden
          done()
        , 100)

      describe 'then going forward in the browser', ->
        beforeEach ->
          history.forward() if history

        it 'shows the modal again', (done) ->
          # Ignore test case if using FF due to browser issue with history.back in iframe
          respondForModalWithSuccess()
          server.respond()
          unless isBrowserFF
            setTimeout( ->
              expect($('#listing-123-modal')).to.be.visible
              done()
            , 100)
          else
            done()

        it 'does not create a new modal', ->
          expect($('#listing-123-modal').length).to.equal(1)

    describe 'when navigating thumbnails', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()

      it 'it wraps when navigating thumbnails forward', ->
        $('#thumbnail-2').closest('[data-role=thumbnail-wrapper]').addClass('selected')
        $('[data-slide=next]').click()
        respondForModalTopWithSuccess()
        server.respond()
        expect($('#thumbnail-1').closest('[data-role=thumbnail-wrapper]')).to.have.class('selected')
        expect($('#thumbnail-2').closest('[data-role=thumbnail-wrapper]')).to.not.have.class('selected')

      it 'it wraps when navigating thumbnails backward', ->
        $('#thumbnail-1').closest('[data-role=thumbnail-wrapper]').addClass('selected')
        $('[data-slide=prev]').click()
        respondForModalTopWithSuccess()
        server.respond()
        expect($('#thumbnail-2').closest('[data-role=thumbnail-wrapper]')).to.have.class('selected')
        expect($('#thumbnail-1').closest('[data-role=thumbnail-wrapper]')).to.not.have.class('selected')

    # XXX: can't figure out how to get these tests to work. send help!

#    describe 'when navigating with the keyboard', ->
#      beforeEach ->
#        respondForModalWithSuccess()
#        server.respond()

#      describe 'and pressing the right arrow key', ->
#        beforeEach ->
#          $('#thumbnail-1').closest('[data-role=thumbnail-wrapper]').addClass('selected')
#          Test.typeSpecial($(document), KEYCODE_RIGHTARROW)
#          respondForModalTopWithSuccess()
#          server.respond()

#        it 'navigates to the second listing', ->
#          expect($('#thumbnail-2').closest('[data-role=thumbnail-wrapper]')).to.have.class('selected')
#          expect($('#thumbnail-1').closest('[data-role=thumbnail-wrapper]')).to.not.have.class('selected')

#        describe 'and then pressing the left arrow key', ->
#          beforeEach ->
#            Test.typeSpecial($(document), KEYCODE_LEFTARROW)
#            respondForModalTopWithSuccess()
#            server.respond()

#          it 'navigates back to the original listing', ->
#            expect($('#thumbnail-1').closest('[data-role=thumbnail-wrapper]')).to.have.class('selected')
#            expect($('#thumbnail-2').closest('[data-role=thumbnail-wrapper]')).to.not.have.class('selected')

    describe 'and entering a comment', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()
        $('#listing-123-modal textarea').val("It's a trap!")
        Test.triggerKeyPress($('#listing-123-modal textarea'), Test.Keys.ENTER)
        respondForCommentsWithSuccess(["It's a trap!"])

      it 'shows the comment in the comment stream', ->
        server.respond()
        expect($('#listing-123-modal [data-role=comment-stream]')).to.contain("It's a trap!")

      it 'clears the comment box', ->
        server.respond()
        expect($('#listing-123-modal textarea').val()).to.equal('')

      it 'focuses the comment box' #, ->
        # Needs to be unpended!  Focus doesn't seem to stick 02/25/2013
        #server.respond()
        #expect($('#listing-123-modal textarea')).to.have.css('focus', true)

      describe 'then entering another comment', ->
        beforeEach ->
          respondForCommentsWithSuccess(["It's a trap!"])
          server.respond()
          # sinon's fake server api does not support overwriting an existing respondWith with one that returns a
          # different response, so replace the first mock server with another one in order to stub the comments
          # endpoint to return both comments.
          server.tearDown()
          server = new MockServer
          $('#listing-123-modal textarea').val("You zerged my Cloudsong!")
          Test.triggerKeyPress($('#listing-123-modal textarea'), Test.Keys.ENTER)
          respondForCommentsWithSuccess(["It's a trap!", "You zerged my Cloudsong!"])

        it 'shows both comments in the comment stream', ->
          server.respond()
          expect($('#listing-123-modal [data-role=comment-stream]')).to.contain("It's a trap!")
          expect($('#listing-123-modal [data-role=comment-stream]')).to.contain("You zerged my Cloudsong!")

        it 'clears the comment box', ->
          server.respond()
          expect($('#listing-123-modal textarea').val()).to.equal('')

        it 'focuses the comment box' #, ->
          # Needs to be unpended!  Focus doesn't seem to stick 02/25/2013
          #server.respond()
          #expect($('#listing-123-modal textarea').is(':focus')).to.be.true

    describe 'and entering a blank comment', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()
        Test.triggerKeyPress($('#listing-123-modal textarea'), Test.Keys.ENTER)
        respondForCommentsWithError()

      it 'adds error formatting', ->
        server.respond()
        expect($('#listing-123-modal .control-group')).to.have.class('error')

      it 'shows an inline error message', ->
        server.respond()
        expect($('#listing-123-modal .control-group .help-block')).to.exist

      describe 'then entering a comment', ->
        beforeEach ->
          server.respond()
          # sinon's fake server api does not support overwriting an existing respondWith with one that returns a
          # different response, so replace the first mock server with another one in order to stub the comments
          # endpoint to return both comments.
          server.tearDown()
          server = new MockServer
          respondForModalWithSuccess()
          server.respond()
          $('#listing-123-modal textarea').val("It's a trap!")
          Test.triggerKeyPress($('#listing-123-modal textarea'), Test.Keys.ENTER)
          respondForCommentsWithSuccess(["It's a trap!"])

        it 'removes error formatting', ->
          server.respond()
          expect($('#listing-123-modal .control-group')).to.not.have.class('error')

        it 'removes inline error message', ->
          server.respond()
          expect($('#listing-123-modal .control-group .help-block')).to.not.exist

    describe 'and clicking the save button', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()
        $('[data-action=save-to-collection-cta]').click()
        $(document).trigger 'saveManager:saved', [{listingId: 123, modalCtas: """
<div data-role="ctas">
<div id="like-count">23</div>
<div id="save-count">6</div>
<button data-toggle="love">Love</button>
<button data-toggle="modal" data-target="#listing-save-to-collection-123-modal"
data-action="save-to-collection-cta">Saved</button>
</div>
"""}]

      it 'hides the listing modal', ->
        expect($('#listing-123-modal')).to.be.hidden

      it 'updates the listing modal ctas', ->
        expect($('#save-count')).to.have.text('6')

      describe 'and closing the collection success modal', ->
        beforeEach ->
          $('#listing-123-modal').modal('hide')
          $(document).trigger 'saveManager:succeeded'

        it 'shows the listing modal', ->
          expect($('#listing-123-modal')).to.be.visible

    describe 'and clicking the like button', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()
        $('[data-toggle=love]').trigger 'loveButton:loved', ["""
<div data-role="ctas">
<div id="like-count">24</div>
<div id="save-count">5</div>
<button data-toggle="love">Loved</button>
<button data-toggle="modal" data-target="#listing-save-to-collection-123-modal"
data-action="save-to-collection-cta">Saved</button>
</div>
"""]

      it 'updates the ctas', ->
        expect($('#like-count')).to.have.text('24')

    describe 'and clicking a thumbnail in the footer', ->
      beforeEach ->
        respondForModalWithSuccess()
        server.respond()

      describe 'and a thumbnail is clicked', ->
        beforeEach ->
          $('#thumbnail-1').click()

        it 'loads the content successfully', ->
          respondForModalTopWithSuccess()
          server.respond()
          expect($('#listing-123-modal')).to.contain('Delicious Ham')

        it 'shows an error when loading the content fails', ->
          respondForModalTopWithFailure()
          server.respond()
          expect($('#listing-123-modal')).to.contain('Oops')

      describe 'and a thumbnail is already selected', ->
        beforeEach ->
          $('#thumbnail-2').closest('[data-role=thumbnail-wrapper]').addClass('selected')
          $('#thumbnail-1').click()

        it 'updates the selected state of the thumbnails', ->
          expect($('#thumbnail-1').closest('[data-role=thumbnail-wrapper]')).to.have.class('selected')
          expect($('#thumbnail-2').closest('[data-role=thumbnail-wrapper]')).to.not.have.class('selected')
