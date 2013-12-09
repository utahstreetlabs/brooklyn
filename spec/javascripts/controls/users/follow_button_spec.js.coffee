#= require spec_helper
#= require controls/users/follow_button

describe 'users.FollowButton', ->
  server = null

  # use regexps to account for the source and page_source params in the query string

  respondWithSuccess = ->
    server.respondWith(/\/profiles\/peter-griffin\/follow/, data: {status: 'success', data:
                      {followeeId: 123, followers: 1, follow: """
<span class="follow-wrap" data-followee="123" data-follower-count="[data-role=profile-followers-count]">
  <button class="social do-unfollow actioned follow btn" data-action="unfollow" data-method="delete" data-target="/profiles/peter-griffin/unfollow" data-toggle="user-follow" name="button" type="button">
    <span class="icons-button-follow"></span>
    Following
  </button>
</span>
"""}})

  beforeEach ->
    $('body').html(JST['templates/controls/users/follow_button']())
    server = new MockServer

  afterEach ->
    server.tearDown()

  describe 'clicking the button on the first peter-griffin card', ->
    beforeEach ->
      $('#listing-modal-1 [data-action=follow]').click()
      respondWithSuccess()

    it 'updates the followers count', ->
      server.respond()
      expect($('#followers-count')).to.contain('1')

    it 'updates the button for the first peter-griffin card', ->
      server.respond()
      expect($('#listing-modal-1 [data-action=unfollow]')).to.contain('Following')

    it 'rebinds the button for the first peter-griffin card', ->
      server.respond()
      expect($('#listing-modal-1 [data-followee=123]').data('userFollowButton').method).to.equal('delete')

    it 'updates the button for the second peter-griffin card', ->
      server.respond()
      expect($('#listing-modal-2 [data-action=unfollow]')).to.contain('Following')

    it 'rebinds the button for the second peter-griffin card', ->
      server.respond()
      expect($('#listing-modal-2 [data-followee=123]').data('userFollowButton').method).to.equal('delete')

    it 'does not update the button for the stewie-griffin card', ->
      server.respond()
      expect($('#listing-modal-3 [data-action=follow]')).to.contain('Follow')

    it 'does not initialize the button for the stewie-griffin card', ->
      server.respond()
      expect($('#listing-modal-3 [data-followee=456]').data('userFollowButton')).to.be.undefined
