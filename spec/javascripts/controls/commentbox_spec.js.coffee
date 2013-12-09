#= require spec_helper
#= require copious
#= require copious/jsend
#= require controls/commentbox

describe 'Commentbox', ->
  # XXX: at some point probably want to load some stub fb friends
  COPIOUSFB ?= {
    postInit: (fn) ->
  }

  beforeEach ->
    $('body').html(JST['templates/controls/commentbox']())

  describe 'typeahead', ->
    server = null
    input = null

    beforeEach ->
      server = new MockServer
      input = $('[data-control=commentbox]')
      input.focus()
    afterEach ->
      server.tearDown()

    getCommentboxKeywords = (input) -> input.data('commentbox').keywordData

    describe 'on typing text', ->
      beforeEach ->
        Test.typeChars(input, 'asdf')

      it 'renders the correct text', ->
        expect(input.val()).to.equal('asdf')

      describe 'and inserting text', ->
        beforeEach ->
          Test.setCaretPos(input, 0)
          input.click()
          Test.typeChars(input, 'asdf ')

        it 'renders the correct text', ->
          expect(input.val()).to.equal('asdf asdf')

        describe 'and inserting first character after #', ->
          beforeEach ->
            server.respondWith('/tags/typeahead?query=a',
              data: {status: 'success', data: {options: [
                {type: 'tag', name: 'Animal', slug: 'animal'},
                {type: 'tag', name: 'Anime', slug: 'anime'}
              ]}})
            Test.setCaretPos(input, 'asdf'.length)
            input.click()
            Test.typeChars(input, ' #a')
            server.respond()

          it 'renders the correct text', ->
            expect(input.val()).to.equal('asdf #a asdf')

          it 'displays the menu', ->
            expect($('.commentbox_menu')).to.be.visible

          it 'populates menu with suggestions', ->
            expect($('.commentbox_menu_item').first().text()).to.equal('Animal')
            expect($('.commentbox_menu_item').last().text()).to.equal('Anime')
            expect($('.commentbox_menu_item').length).to.equal(2)

          it 'has the first item selected', ->
            expect($('.commentbox_menu_item').first()).to.have.class('active')

          describe 'after pressing enter', ->
            beforeEach ->
              Test.typeSpecial(input, KEYCODE_ENTER)

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #Animal  asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['Animal']
              expect(keyword.id).to.equal('animal')
              expect(keyword.name).to.equal('Animal')
              expect(keyword.type).to.equal('tag')

          describe 'after pressing tab', ->
            beforeEach ->
              Test.typeSpecial(input, KEYCODE_TAB)

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #Animal  asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['Animal']
              expect(keyword.id).to.equal('animal')
              expect(keyword.name).to.equal('Animal')
              expect(keyword.type).to.equal('tag')

          describe 'after clicking a list item', ->
            beforeEach ->
              $('.commentbox_menu_item').last().trigger('mouseenter').trigger('mouseup')

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #Anime  asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['Anime']
              expect(keyword.id).to.equal('anime')
              expect(keyword.name).to.equal('Anime')
              expect(keyword.type).to.equal('tag')

          describe 'after moving out of hashtag with arrow keys', ->
            beforeEach ->
              Test.setCaretPos(input, Test.getCaretPos(input) + 1)
              Test.typeSpecial(input, KEYCODE_RIGHTARROW)

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #a asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['a']
              expect(keyword.id).to.equal('a')
              expect(keyword.name).to.equal('a')
              expect(keyword.type).to.equal('tag')

          describe 'after moving out of hashtag by clicking elsewhere in text', ->
            beforeEach ->
              Test.setCaretPos(input, 'asdf'.length)
              input.click()

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #a asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['a']
              expect(keyword.id).to.equal('a')
              expect(keyword.name).to.equal('a')
              expect(keyword.type).to.equal('tag')

          describe 'after pressing esc key', ->
            beforeEach ->
              Test.typeSpecial(input, KEYCODE_ESC)

            it 'renders the correct text', ->
              expect(input.val()).to.equal('asdf #a asdf')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['a']
              expect(keyword.id).to.equal('a')
              expect(keyword.name).to.equal('a')
              expect(keyword.type).to.equal('tag')

    describe 'on typing first character after #', ->
      beforeEach ->
        server.respondWith('/tags/typeahead?query=a',
          data: {status: 'success', data: {options: [
            {type: 'tag', name: 'Animal', slug: 'animal'},
            {type: 'tag', name: 'Anime', slug: 'anime'}
          ]}})
        Test.typeChars(input, '#a')
        server.respond()

      it 'renders the correct text', ->
        expect(input.val()).to.equal('#a')

      it 'displays the menu', ->
        expect($('.commentbox_menu')).to.be.visible

      it 'populates menu with suggestions', ->
        expect($('.commentbox_menu_item').first().text()).to.equal('Animal')
        expect($('.commentbox_menu_item').last().text()).to.equal('Anime')
        expect($('.commentbox_menu_item').length).to.equal(2)

      it 'has the first item selected', ->
        expect($('.commentbox_menu_item').first()).to.have.class('active')

      it 'allows menu navigation with arrow keys', ->
        Test.typeSpecial(input, KEYCODE_DOWNARROW)
        expect($('.commentbox_menu_item').last()).to.have.class('active')

      it 'wraps around when navigating menu with arrow keys', ->
        Test.typeSpecial(input, KEYCODE_UPARROW)
        expect($('.commentbox_menu_item').last()).to.have.class('active')

      describe 'after pressing enter', ->
        beforeEach ->
          Test.typeSpecial(input, KEYCODE_ENTER)

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        it 'replaces the prefix with the selection and a space', ->
          expect(input.val()).to.equal('#Animal ')

        it 'stores the tag in the keyword list', ->
          keyword = getCommentboxKeywords(input)['Animal']
          expect(keyword.id).to.equal('animal')
          expect(keyword.name).to.equal('Animal')
          expect(keyword.type).to.equal('tag')

      describe 'after pressing tab', ->
        beforeEach ->
          Test.typeSpecial(input, KEYCODE_TAB)

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        it 'replaces the prefix with the selection and a space', ->
          expect(input.val()).to.equal('#Animal ')

        it 'stores the tag in the keyword list', ->
          keyword = getCommentboxKeywords(input)['Animal']
          expect(keyword.id).to.equal('animal')
          expect(keyword.name).to.equal('Animal')
          expect(keyword.type).to.equal('tag')

      describe 'after clicking a list item', ->
        beforeEach ->
          $('.commentbox_menu_item').last().trigger('mouseenter').trigger('mouseup')

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        it 'replaces the prefix with the selection and a space', ->
          expect(input.val()).to.equal('#Anime ')

        it 'stores the tag in the keyword list', ->
          keyword = getCommentboxKeywords(input)['Anime']
          expect(keyword.id).to.equal('anime')
          expect(keyword.name).to.equal('Anime')
          expect(keyword.type).to.equal('tag')

      describe 'after pressing space', ->
        beforeEach ->
          server.respondWith('/tags/typeahead?query=a ',
            data: {status: 'success', data: {options: [
              {type: 'tag', name: 'a b c', slug: 'a-b-c'},
              {type: 'tag', name: 'a shirt', slug: 'a-shirt'}
            ]}})
          Test.typeChars(input, ' ')
          server.respond()

        it 'renders the correct text', ->
          expect(input.val()).to.equal('#a_')

        it 'displays the menu', ->
          expect($('.commentbox_menu')).to.be.visible

        # XXX: un-comment below after adding functionality to query on pressing space key
        it 'populates menu with suggestions'#, ->
#         expect($('.commentbox_menu_item').first().text()).to.equal('a b c')
#         expect($('.commentbox_menu_item').last().text()).to.equal('a shirt')
#         expect($('.commentbox_menu_item').length).to.equal(2)

        it 'has the first item selected', ->
          expect($('.commentbox_menu_item').first()).to.have.class('active')

        describe 'and typing text', ->
          beforeEach ->
            server.respondWith('/tags/typeahead?query=a+b',
              data: {status: 'success', data: {options: [
                {type: 'tag', name: 'a b c', slug: 'a-b-c'},
                {type: 'tag', name: 'a bear', slug: 'a-bear'}
              ]}})
            Test.typeChars(input, 'b')
            server.respond()

          it 'renders the correct text', ->
            expect(input.val()).to.equal('#a_b')

          describe 'then pressing two spaces', ->
            beforeEach ->
              Test.typeChars(input, ' ')
              Test.typeChars(input, ' ', {setValueAfterChange: true})

            it 'renders the correct text', ->
              expect(input.val()).to.equal('#a_b ')

            it 'hides the menu', ->
              expect($('.commentbox_menu')).to.be.hidden

            it 'stores the tag in the keyword list', ->
              keyword = getCommentboxKeywords(input)['a_b']
              expect(keyword.id).to.equal('a-b')
              expect(keyword.name).to.equal('a b')
              expect(keyword.type).to.equal('tag')

        describe 'and pressing a second space', ->
          beforeEach ->
            Test.typeChars(input, ' ', {setValueAfterChange: true})

          it 'renders the correct text', ->
            expect(input.val()).to.equal('#a ')

          it 'hides the menu', ->
            expect($('.commentbox_menu')).to.be.hidden

          it 'stores the tag in the keyword list', ->
            keyword = getCommentboxKeywords(input)['a']
            expect(keyword.id).to.equal('a')
            expect(keyword.name).to.equal('a')
            expect(keyword.type).to.equal('tag')

      describe 'after deleting all text', ->
        beforeEach ->
          Test.typeBackspace(input)

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        describe 'and re-entering the same char', ->
          beforeEach ->
            Test.typeChar(input, 'a')

          it 're-displays menu for same char', ->
            expect($('.commentbox_menu')).to.be.visible
            expect($('.commentbox_menu_item').first().text()).to.equal('Animal')
            expect($('.commentbox_menu_item').last().text()).to.equal('Anime')

        describe 'and entering a different char', ->
          beforeEach ->
            server.respondWith('/tags/typeahead?query=b',
              data: {status: 'success', data: {options: [
                {type: 'tag', name: 'Big', slug: 'big'},
                {type: 'tag', name: 'Bronze', slug: 'bronze'}
              ]}})
            Test.typeChar(input, 'b')
            server.respond()

          it 're-displays menu with new words', ->
            expect($('.commentbox_menu')).to.be.visible
            expect($('.commentbox_menu_item').first()).to.have.text('Big')
            expect($('.commentbox_menu_item').last()).to.have.text('Bronze')

      describe 'when there is no match for the tag', ->
        beforeEach ->
          server.respondWith('/tags/typeahead?query=ab',
            data: {status: 'success', data: {options: []}})
          Test.typeChar(input, 'b')
          server.respond()

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        describe 'and the user presses enter', ->
          it 'stores the tag in the keyword list', ->
            Test.typeSpecial(input, KEYCODE_ENTER)
            keyword = getCommentboxKeywords(input)['ab']
            expect(keyword.id).to.equal('ab')
            expect(keyword.name).to.equal('ab')
            expect(keyword.type).to.equal('tag')

    describe 'on typing first character after @', ->
      beforeEach ->
        fbFriends = [{type: 'fb', name: 'June July', id: '01234'}]
        $('[data-control=commentbox]').data('commentbox').managers['@'].insertMany(fbFriends)
        server.respondWith('/profiles/typeahead?query=j',
          data: {status: 'success', data: {options: [
            {type: 'cf', name: 'John Doe', id: 'john-doe'},
            {type: 'cf', name: 'Jane Doe', id: 'jane-doe'}
          ]}})
        Test.typeChars(input, '@j')
        server.respond()

      it 'renders the correct text', ->
        expect(input.val()).to.equal('@j')

      it 'displays the menu', ->
        expect($('.commentbox_menu')).to.be.visible

      it 'populates menu with suggestions', ->
        expect($('.commentbox_menu_item').eq(0).text()).to.equal('Jane Doe')
        expect($('.commentbox_menu_item').eq(1).text()).to.equal('John Doe')
        expect($('.commentbox_menu_item').eq(2).text()).to.equal('June July')
        expect($('.commentbox_menu_item').length).to.equal(3)

      it 'contains profile images for suggestions', ->
        expect($('.commentbox_menu_item img.avatar').length).to.equal(3)

      it 'contains social icons for FB suggestions', ->
        expect($('.commentbox_menu_item .connected-network.facebook').length).to.equal(1)

      describe 'after pressing enter', ->
        beforeEach ->
          Test.typeSpecial(input, KEYCODE_ENTER)

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        it 'replaces the prefix with the selection (spaces replaced with underscores) and a space', ->
          expect(input.val()).to.equal('@Jane_Doe ')

      describe 'after clicking a list item', ->
        beforeEach ->
          $('.commentbox_menu_item').last().trigger('mouseenter').trigger('mouseup')

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        it 'replaces the prefix with the selection (spaces replaced with underscores) and a space', ->
          expect(input.val()).to.equal('@June_July ')

      describe 'after deleting all text', ->
        beforeEach ->
          Test.typeBackspace(input)

        it 'hides the menu', ->
          expect($('.commentbox_menu')).to.be.hidden

        describe 'and typing different character with new suggestions', ->
          beforeEach ->
            server.respondWith('/profiles/typeahead?query=a',
              data: {status: 'success', data: {options: [
                {type: 'cf', name: 'ARTHUR DOE', id: 'arthur-doe'},
                {type: 'cf', name: 'Adam Doe', id: 'adam-doe'},
                {type: 'cf', name: 'Amy Doe', id: 'amy-doe'},
                {type: 'cf', name: 'John Doe', id: 'john-doe'},
                {type: 'cf', name: 'Jane Doe', id: 'jane-doe'},
                {type: 'cf', name: 'Adam Doe', id: 'adam-doe1'}
              ]}})
            Test.typeChars(input, 'a')
            server.respond()

          it 're-displays menu', ->
            expect($('.commentbox_menu')).to.be.visible

          it 'displays menu with only relevant results', ->
            expect($('.commentbox_menu_item').length).to.equal(4)

          it 'displays menu with results sorted', ->
            results = $('.commentbox_menu_item')
            expect(results.eq(0).text()).to.equal('Adam Doe')
            expect(results.eq(1).text()).to.equal('Adam Doe') # checks duplicates not excluded
            expect(results.eq(2).text()).to.equal('Amy Doe')
            expect(results.eq(3).text()).to.equal('ARTHUR DOE') # checks case-insensitive

    describe 'on typing with multiple lines of text in textbox', ->
      beforeEach ->
        input.val('Lorem ipsum dolor sit amet, #consectetur adipisicing elit, #sed do eiusmod tempor incididunt ut
                  labore et #dolore magna aliqua...')
        input.css('width', '200px')

      describe 'and not in typeahead mode', ->
        prevCaretPos = null

        beforeEach ->
          Test.setCaretPos(input, 'Lorem ipsum dolor sit amet'.length)
          prevCaretPos = Test.getCaretPos(input)

        describe 'after pressing up/down arrow key', ->
          keyBlocked = true

          beforeEach ->
            Test.typeSpecial(input, KEYCODE_DOWNARROW)
            $(document).on('keyup', (event) =>
              keyBlocked = false if event.target is input.get(0)
            )

          it 'hides the menu', ->
            expect($('.commentbox_menu')).to.be.hidden

          it 'changes the caret position', ->
            assert.equal(keyBlocked, false)

      describe 'and in typeahead mode', ->
        beforeEach ->
          Test.setCaretPos(input, 'Lorem ipsum dolor sit amet, #'.length)
        
        describe 'after pressing up/down arrow key', ->
          beforeEach ->
            Test.typeSpecial(input, KEYCODE_DOWNARROW)

          # XXX: fill in below after adding functionality to show menu on up/down arrow key if in typeahead mode
          it 'displays the menu'

          it 'populates menu with suggestions'

          it 'has the first item selected'

          it 'allows navigation with arrow keys'

          it 'does not change the caret position'
