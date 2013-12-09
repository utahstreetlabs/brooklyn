module InternalListings
  module Sync
    extend ActiveSupport::Concern

    included do
      validates :source_uid, uniqueness: {scope: [:seller_id]}, allow_nil: true
    end

    # Returns if a particular photo is associated with this listing
    # @param [String] source_uid unique identifier of photo
    def has_sourced_photo?(source_uid)
      photos.where('source_uid' => source_uid).count > 0
    end

    # attaches all files (passed as an enumerable of +Brooklyn::CarrierWave::ImageFile+ instances) to this listing
    # if the uid of the image is found in the db, the photo is ignored
    # listings that cannot be sync'd for any reason are also ignored, with an error logged
    def attach_photos(files)
      uids = photos.each_with_object(Set.new) do |photo,set|
        # this method depends on the presence of source_uids and the mass-assignment debacle has left duplicate photos
        # without a source_uid all over AJM, so clean those up on the fly
        if photo.source_uid.present?
          set.add(photo.source_uid)
        else
          photos.delete(photo)
        end
      end
      files.each do |image|
        begin
          unless uids.member?(image.uid)
            photo = photos.build
            photo.source_uid = image.uid
            photo.file.cache!(image)
            photo.save!
          end
        rescue Exception => e
          msg = "Error syncing listing photo for listing #{id}: #{e}"
          logger.error(msg)
          Airbrake.notify(error_class: "Error syncing listing photo", error_message: msg,
                          parameters: {listing_id: id, source_uid: image.uid})
        end
      end
    end

    def add_remote_photo!(source_uid=nil, href)
      photo = photos.build(source_uid: source_uid)
      photo.file.download!(href)
      photo.save!
      photo
    end

    module ClassMethods
      def tags_from_cache(names, cache, create=false)
        (names || []).map { |n| [n, Tag.compute_slug(n)] }.each_with_object({}) do |(name,slug),hash|
          tag = cache[slug]
          tag ||= Tag.create(name: name, slug: slug) if create
          hash[slug] = tag if tag
        end
      end

      # injects or updates the listing content in the sync adapter, using cache information passed in
      def create_or_update_from_source_adapter(seller, adapter, categories, tags)
        raise "Can't sync listings without source_uid" unless adapter.uid
        listing = find_or_initialize_by_seller_id_and_source_uid(seller.id, adapter.uid)
        listing.attributes = adapter.attributes
        if listing.new_record?
          # only set pricing version if it's a new listing.  automatically modifying is unlikely the desired result
          listing.pricing_version = adapter.pricing_version if adapter.pricing_version
        end
        listing.category = categories[adapter.category_slug]
        listing.condition = adapter.condition

        listing_tags = self.tags_from_cache(adapter.tag_names_no_create, tags)
        listing_tags.merge!(self.tags_from_cache(adapter.tag_names, tags, true))
        listing.tags = listing_tags.values
        listing.save!

        listing.attach_photos(adapter.photo_files)
        listing.complete if listing.incomplete?
        listing.activate if listing.inactive?
        [listing, listing_tags]
      end

      # Return a query scope for listings from this seller that *have* a source_uid, but it's not in the provided list.
      def cancel_all_by_uid!(uids)
        self.where(source_uid: uids).each { |l| l.cancel! }
      end

      def cancellable_uids(seller)
        Set.new(self.cancellable.where(seller_id: seller.id).where('source_uid IS NOT NULL').select(:source_uid).
          map(&:source_uid))
      end

      def sync(source_class)
        raise "Syncing listings without seller slug in source '#{source_class.inspect}" unless source_class.seller_slug
        seller = User.find_by_slug(source_class.seller_slug)
        raise "Attempted to sync listings for non-existent seller slug '#{source_class.seller_slug}" unless seller
        # load all the current uids.  we'll remove them as we see them, and cancel anything that's left over
        uids = self.cancellable_uids(seller)
        categories = Category.all.each_with_object({}) { |c,h| h[c.slug] = c }
        tags = Tag.all.each_with_object({}) { |t,h| h[t.slug] = t }
        source_class.new.each_with_index do |adapter,index|
          # some of the prod errors are from calling uid on a nil, so need to be careful here
          self.with_error_handling("Sync listing", (adapter ? {listing_uid: adapter.uid} : {})) do
            listing, ltags = self.create_or_update_from_source_adapter(seller, adapter, categories, tags)
            uids.delete(adapter.uid)
            tags.merge!(ltags)
          end
        end
        # XXX: we actually want to mark these sold, but there's a chunk of work in there, so we'll cancel them for now.
        self.cancel_all_by_uid!(uids.to_a)
      end

      def sync_all_sources
        ::Sync::Listings.active_sources.each do |source_class|
          begin
            sync(source_class)
          rescue Exception => e
            logger.error(e)
            raise
          end
        end
      end
    end
  end
end
