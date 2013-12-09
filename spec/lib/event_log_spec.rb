require 'spec_helper'

describe Brooklyn::EventLog do
  describe '#setup' do
    it 'logs a controller event' do
      Brooklyn::EventLog.expects(:log_controller_event).with(is_a(ActiveSupport::Notifications::Event))
      ActiveSupport::Notifications.instrument('process_action.action_controller')
    end

    it 'does not log a skipped controller event' do
      Brooklyn::EventLog.expects(:log_controller_event).never
      ActiveSupport::Notifications.instrument('process_action.action_controller', skip: true)
    end

    it 'logs a custom event' do
      Brooklyn::EventLog.expects(:log_custom_event).with(is_a(ActiveSupport::Notifications::Event))
      ActiveSupport::Notifications.instrument('poop.brooklyn')
    end
  end
end
