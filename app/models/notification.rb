require 'lagunitas/models/notification'

class Notification < LadonDecorator
  decorates Lagunitas::Notification

  def type
    decorated.class.name.demodulize.to_sym
  end
end
