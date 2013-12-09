require 'active_support/concern'

module Listings
  # An approved listing has a story injected into the Everything feed and the New Arrivals browse. A disapproved
  # listing has neither. Every story, regardless of approval, disapproval, or lack thereof, has a story injected
  # into the Your Likes & Follows feed at activation time and shows up through all search and browse mechanisms
  # other than New Arrivals.
  module Approval
    extend ActiveSupport::Concern

    included do
      scope :approved,         where(approved: true)
      scope :disapproved,      where(approved: false)
      scope :not_yet_approved, where(approved: nil)
    end

    def disapproved?
      !not_yet_approved? && !approved?
    end

    def not_yet_approved?
      approved.nil?
    end

    # Marks the listing approved and injects an activation story into the Everything feed.
    #
    # @param [Hash] options
    # @option options [Boolean] :persist whether or not to save the updated listing state
    def approve!(options = {})
      persist = options.fetch(:persist, true)
      transaction do
        self.approved = true
        self.approved_at = Time.now
        save! if persist
        AfterApprovalJob.enqueue(self.id)
      end
    end

    # Marks the listing disapproved. Does not inject an activation story into the Everything feed.
    #
    # @param [Hash] options
    # @option options [Boolean] :persist whether or not to save the updated listing state
    def disapprove!(options = {})
      persist = options.fetch(:persist, true)
      transaction do
        self.approved = false
        self.approved_at = Time.now
        save! if persist
        AfterDisapprovalJob.enqueue(self.id)
      end
    end

    module ClassMethods
      # Returns all active listings which have not yet been approved.
      #
      # @option options [Integer] +seller_id+ limits the returned listings to those sold by this user
      # @option options [Object] +includes+ includes these associated objects
      # @option options [Integer] +page+ paginates the returned listings, returning only this page
      # @return [ActiveRecord::Relation]
      def available_for_approval(options = {})
        scope = with_state(:active).not_yet_approved.order(:activated_at)
        scope = scope.where(seller_id: options[:seller_id]) if options[:seller_id]
        scope = scope.includes(options[:includes]) if options[:includes]
        scope = scope.page(options[:page]) if options[:page]
        scope
      end

      # Returns the count of active listings which have not yet been approved for each seller with such listings.
      #
      # @return [Hash] seller id => count
      def available_for_approval_counts
        scope = select('seller_id, COUNT(*) AS count').with_state(:active).not_yet_approved.group(:seller_id)
        scope.each_with_object({}) {|l, m| m[l.seller_id] = l.count}
      end

      # Approves each of the given listings, silently handling any errors that may occur.
      def approve_all(listings)
        listings.each do |listing|
          with_error_handling("Approve listing", listing_id: listing.id) do
            listing.approve!
          end
        end
      end

      # Disapproves each of the given listings, silently handling any errors that may occur.
      def disapprove_all(listings)
        listings.each do |listing|
          with_error_handling("Disapprove listing", listing_id: listing.id) do
            listing.disapprove!
          end
        end
      end
    end
  end
end
