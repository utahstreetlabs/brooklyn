class ExternalListing < Listing
  belongs_to :source, class_name: 'ListingSource', foreign_key: :listing_source_id
  delegate :url, to: :source

  attr_reader :source_image, :source_image_id
  attr_accessor :initial_comment
  attr_accessible :source_image, :source_image_id, :initial_comment

  validates :source_image_id, presence: true, if: :new_record?

  after_create do
    # Without wrapping the following in a transaction with +requires_new+ == true, a validation
    # exception will result in the +ActiveRecord::Rollback+ exception being propagated up the stack.
    # This is counter-intuitive; see more here:
    # http://stackoverflow.com/questions/4962359/activerecord-mysql-and-nested-transactions-whats-the-behavior
    Listing.transaction(requires_new: true) do
      create_primary_photo_from_source_image!
      complete!
      activate!
      create_seller_like
    end
  end

  def source_image=(value)
    @source_image = value
    @source_image_id = value.present? ? value.id : nil
  end

  def source_image_id=(value)
    @source_image_id = value
    @source_image = value.present? ? ListingSourceImage.find_by_id(value) : nil
  end

  def create_primary_photo_from_source_image!
    return nil unless source_image
    # all photo processing is done in the foreground so that we have a cover photo as soon as the listing is activated
    photo_attrs = {}
    if source_image.url =~ /^https?/ # same check CarrierWave uses to see if a file is remote
      photo_attrs[:remote_file_url] = source_image.url
    else
      # useful for uploading local files in tests
      url = source_image.url.gsub(/^file\:\/\//, '')
      photo_attrs[:file] = File.new(url)
    end
    photo = photos.build(photo_attrs)
    photo.save!
    photo
  end

  def create_seller_like
    seller.like(self)
  end

  def supports_original_price?
    false
  end

  def supports_shipping?
    false
  end

  def supports_checkout?
    false
  end

  def supports_make_an_offer?
    false
  end

  def supports_recommend?
    true # thumbs up from Jim
  end

  def supports_dimensions?
    false
  end

  def supports_handling?
    false
  end

  def self.new_from_source(source)
    listing = new(title: source.title, price: source.price)
    listing.source = source
    listing.source_image = source.relevant_images.first
    listing
  end

  def self.find_with_url(url)
    joins(:source).where("#{ListingSource.quoted_table_name}.url = ?", url).first
  end

  # XXX: have to override the class-level accessors defined by Sluggable and Likeable since the way they define the
  # methods is not compatible with STI.

  def self.slug_field
    Listing.slug_field
  end

  def self.sluggable_field
    Listing.sluggable_field
  end

  def self.likeable_type
    :listing
  end

  def self.likeable_type_attr
    :listing_id
  end
end
