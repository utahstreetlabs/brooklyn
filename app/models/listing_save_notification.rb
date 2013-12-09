class ListingSaveNotification < ListingNotification
  attr_accessor :saver, :collection 

  def complete?
    super && !saver.nil? && !collection.nil?
  end
end
