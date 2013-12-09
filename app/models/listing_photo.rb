class ListingPhoto < ActiveRecord::Base
  include ApiAccessable

  attr_accessible :position

  # set to true if we want to push most photo processing into the background
  attr_accessor :background_processing
  has_uuid

  belongs_to :listing
  acts_as_list :scope => :listing

  mount_uploader :file, ListingPhotoUploader

  validates :file, :presence => true

  attr_accessible :file, :remote_file_url, :background_processing, :source_uid

  after_destroy do
    remove_file!
    listing.uncomplete! if listing.can_uncomplete? and not listing.has_photos?
  end

  def version_url(version)
    file.send(version).url
  end

  # return image dimensions as [height, width] tuple
  # will use imagemagick to calculate them if necessary, which is slow
  # and blocking, so for the love of god don't do this inline in a request
  def image_dimensions
    unless self.height && self.width
      self.height, self.width = file.calculate_geometry
      if persisted?
        self.update_column(:height, self.height)
        self.update_column(:width, self.width)
      end
    end
    [self.height, self.width]
  end

  def update_uploaded_photo!(upload)
    self.file = upload
    self.save!
    self
  end

  def update_remote_photo!(source_uid = nil, href)
    self.file.download!(href)
    self.save!
    self
  end

  # returns a hash of listing_id's mapped to listing_photos that are the primary photos (if found) for each of the
  # listings passed in
  def self.find_primaries(listings, options = {})
    listing_ids = listings.map {|l| l.is_a?(Integer) ? l : l.id}
    # unfortunately, it seems to be possible to create multiple entries in the db for a single (listing_id, position)
    # pair, so we have to get all the photos and take the first one for each listing
    # rather than do anything smart, we just order descending by position and overwrite the hash (on listing id) until
    # the last one (the lowest position)
    if listing_ids.any?
      logger.debug "Finding primary photos for listings #{listing_ids}"
      scope = self.where(listing_id: listing_ids).order('listing_id, position DESC')
      scope = scope.includes(options[:includes]) if options[:includes]
      scope.each_with_object({}) do |photo,hash|
        hash[photo.listing_id] = photo
      end
    else
      {}
    end
  end
end
