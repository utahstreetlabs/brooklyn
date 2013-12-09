#= require spec_helper
#= require controls/layout/notification_counter

describe 'layout.NotificationCounter', ->
  beforeEach ->
    $('body').html(JST['templates/controls/layout/notification_counter']())
    $('#pill').notificationCounter()

  describe 'when the badge is visible', ->
    beforeEach ->
      $('#pill').notificationCounter('instance').invisible = false

    describe 'and unread notifications are available', ->
      beforeEach ->
        $(document).trigger 'notificationcount:more', 5

      it 'updates the badge', ->
        expect($('#pill')).to.have.text('5')

      it 'shows the badge', ->
        expect($('#pill')).to.be.visible

    describe 'and no unread notifications are available', ->
      beforeEach ->
        $(document).trigger 'notificationcount:more', 0

      it 'empties the badge', ->
        expect($('#pill')).to.not.have.text

      it 'hides the badge', ->
        expect($('#pill')).to.be.hidden

  describe 'when the badge is not visible', ->
    beforeEach ->
      $('#pill').notificationCounter('instance').invisible = true

    describe 'and unread notifications are available', ->
      beforeEach ->
        $(document).trigger 'notificationcount:more', 5

      it 'updates the badge', ->
        expect($('#pill')).to.have.text('5')

      it 'leaves the badge hidden', ->
        expect($('#pill')).to.be.hidden

    describe 'and no unread notifications are available', ->
      beforeEach ->
        $(document).trigger 'notificationcount:more', 0

      it 'empties the badge', ->
        expect($('#pill')).to.not.have.text

      it 'leaves the badge hidden', ->
        expect($('#pill')).to.be.hidden
