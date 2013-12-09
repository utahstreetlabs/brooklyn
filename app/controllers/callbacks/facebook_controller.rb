class Callbacks::FacebookController < CallbacksController
  # Overrides the default connected callback; we look for responses specific
  # to facebook.
  def connected
    trigger_action = nil
    if flash.alert
      trigger_action = 'facebook:connectFailed'
    elsif flash.notice && flash.notice == I18n.t('controllers.auth.facebook_timeline')
      trigger_action = 'facebook:connectCancelled'
    else
      trigger_action = 'facebook:connectComplete'
    end
    render 'callbacks/shared', layout: false, locals: {trigger_action: trigger_action}
  end
end
