class ReapGuests < Ladon::Job
  @queue = :reap_guests

  def self.work
    User.find_expired_guests.each do |user|
      user.destroy
    end
  end
end
