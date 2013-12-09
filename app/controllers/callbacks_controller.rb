class CallbacksController < ApplicationController
  skip_requiring_login_only

  def shared
    # used when sharing to a network whose dialog redirects rather
    # than closing itself. the view simply includes some javascript
    # calls a callback in the parent window and closes the current window
    render layout: false, locals: {trigger_action: 'shareComplete'}
  end

  def connected
    # Similar to shared above, calls a callback in the parent window
    # that closes the current window.  Only trigger connectComplete if
    # no error has been rendered.
    trigger_action = flash.alert ? 'connectFailed' : 'connectComplete'
    render layout: false, action: 'shared', locals: {trigger_action: trigger_action}
  end
end
