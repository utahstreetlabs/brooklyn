#= require spec_helper
#= require controls/follow_friends_modal

describe 'Follow friends modal', ->
  server = null
  subject = null

  beforeEach ->
    server = new MockServer
    server.respondWith(FollowFriendsModal.SUGGESTIONS_URL,
                       data: {status: 'success', data: {suggestions: JST['templates/controls/follow_friends_modal_suggestions']()}})
    $('body').html(JST['templates/controls/follow_friends_modal']())
    subject = $('[data-role=follow-friends-modal]').followFriendsModal('instance')
    server.respond()

  describe '#inviteRecipientIds', ->
    it 'should return the ids of selected invite selectables', ->
      expect(subject.inviteRecipientIds()).to.be(['checked-invite'])

  describe '#followeeIds', ->
    it 'should return the ids of selected follow selectables', ->
      expect(subject.followeeIds()).to.be(['checked-follow'])

  describe '#follow', ->
    it 'should post to the follow complete url', ->
      followSpy = sinon.spy()
      server.respondWith($('[data-role=follow-friends-form]').attr('action'), data: {status: 'success'})
      subject.follow().then ->
        followSpy()
      server.respond()
      expect(followSpy).to.have.been.called

  describe '#invite', ->
    initializeFacebook()
    it 'should call FB.ui', ->
      FB.ui = sinon.spy()
      subject.recipients=['12345', '678910']
      subject.invite()
      fbRequest = {method: "apprequests", message: "Travis Vachon wants to follow you on Copious!", to: "12345,678910"}
      expect(FB.ui).to.have.been.calledWith(fbRequest, sinon.match.func).once
