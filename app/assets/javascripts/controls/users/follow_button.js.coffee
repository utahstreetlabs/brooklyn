#= require copious/jsend
#= require copious/tracking

class UserFollowButtonContainer
  constructor: (@element) ->
    @bound = false

  # Binds the container to components within it. The container may be rebound without side effect, which is useful
  # if the dom within the container element changes after initial binding.
  bind: () =>
    # if the container is already bound, this rebinds it
    @countSelector = @element.data('follower-count')
    @buttonElement = @element.find('[data-toggle=user-follow]')
    @url = @buttonElement.data('target')
    @method = @buttonElement.data('method')
    @bound = true

  # Performs an ajax request to either create or destroy a follow. Binds the container if it is not already bound.
  toggle: () =>
    this.bind() unless @bound

    query = {
      source: copious.source(@buttonElement),
      page_source: copious.pageSource(),
    }
    $.jsend.ajax(@url, query, @method).then((data) =>
      $(document).trigger "userFollowButton:updated", [data]
    )

  # Updates follow buttons and follower counts given a data object returned from a +userFollowButton:updated+ event.
  update: (data) =>
    this.bind() unless @bound

    if data.followers?
      if @countSelector?
        $(@countSelector).html(data.followers)
    if data.follow?
      $new = $(data.follow)
      @element.replaceWith($new)
      $new.userFollowButton('bind')

jQuery ->
  # plugin definition
  $.fn.userFollowButton = (option) ->
    args = Array.prototype.slice.call(arguments)
    $(this).each ->
      $element = $(this)
      button = $element.data('userFollowButton')
      unless button
        $element.data('userFollowButton', (button = new UserFollowButtonContainer($element)))
      if typeof option is 'string'
        button[option].apply(button, args[1..])

  # data api
  $(document).on 'click', '[data-toggle=user-follow]', (e) ->
    $(this).closest('[data-followee]').userFollowButton('toggle')

  $(document).on 'userFollowButton:updated', (e, data) ->
    if data.followeeId?
      $(document).find("[data-followee=#{data.followeeId}]").userFollowButton('update', data)
