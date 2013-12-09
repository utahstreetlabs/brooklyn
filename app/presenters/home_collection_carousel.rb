class HomeCollectionCarousel < CollectionCards
  def initialize(viewer, options = {})
    collections = Collection.find_most_followed(window: self.class.config.window, limit: self.class.config.limit,
                                                exclude_owners: viewer, min_listings: self.class.config.min_listings)
    collections = collections.sample(self.class.config.sample_size)
    super(viewer, collections, options)
  end

  def each_group
    each_slice(self.class.config.group_size)
  end

  def group_count
    (cards.size / self.class.config.group_size.to_f).ceil
  end

  def self.config
    Brooklyn::Application.config.home.collection_carousel
  end
end
