require 'resque'
require 'ladon'
require 'faraday'

class NotifyHelloSociety < Ladon::Job
  include Brooklyn::Urls
  @queue = :tracking

  def self.work(campaign)
    Faraday.get(tracking_url(campaign))
  end

  def self.tracking_url(campaign)
    "https://hellosociety.com/tracker/img1.php?userid=356&campaign=#{url_escape(campaign)}&medium=HardPin&source=Pinterest"
  end
end
