class ControllerObserverBase < ActiveModel::Observer
  include Brooklyn::Observer
  include Brooklyn::Sprayer

  class_attribute :controller
  delegate :set_flash_message, to: :controller
end
