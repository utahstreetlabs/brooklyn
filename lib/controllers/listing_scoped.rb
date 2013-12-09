module Controllers
  # Provides common behaviors for controllers that are scoped to a listing.
  module ListingScoped
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval <<-EOT
        helper_method :buyer?, :seller?
      EOT
    end

    module ClassMethods
      def listing_scope(options = {})
        scope = Listing.scoped
        scope = scope.with_states(options[:states]) if options.include?(:states)
        scope = scope.includes(options[:includes]) if options.include?(:includes)
        scope
      end

      def set_listing(options = {})
        before_filter(options) do
          @listing = self.class.listing_scope(options).find_by_slug!(params[:listing_id] || params[:id])
        end
      end

      def require_listing(options = {})
        before_filter(options) do
          states = options.fetch(:state, [])
          states = [states] unless states.is_a?(Array)
          unless @listing && (states.empty? || states.include?(@listing.state.to_sym))
            logger.warn("Disallowing as listing #{@listing.id} is in state: #{@listing.state} not in state: #{states.join(', ')}")
            options[:flash] = "#{options[:flash]}.#{@listing.state}" if options[:flash]
            disallow(options)
          end
        end
      end

      def require_buyer(options = {})
        before_filter(options) do
          unless buyer?
            logger.warn("Disallowing as current user is not buyer of listing #{@listing.id}")
            disallow(options)
          end
        end
      end

      def require_seller(options = {})
        before_filter(options) do
          unless seller?
            logger.warn("Disallowing as current user is not seller of listing #{@listing.id}")
            disallow(options)
          end
        end
      end

      def require_buyer_or_seller(options = {})
        before_filter(options) do
          unless buyer? || seller?
            logger.warn("Disallowing as current user is not buyer or seller of listing #{@listing.id}")
            disallow(options)
          end
        end
      end

      def require_not_seller(options = {})
        before_filter(options) do
          if seller?
            logger.warn("Disallowing as current user is seller of listing #{@listing.id}")
            disallow(options)
          end
        end
      end

      def require_no_order(options = {})
        around_filter do |controller, action|
          begin
            action.call
          rescue OrderAlreadyInitiated => e
            logger.warn("Disallowing as order already initiated for listing #{@listing.id}: #{e.message}")
            disallow(options)
          end
        end
      end

      def require_order(options = {})
        before_filter(options) do
          opts = options.dup
          statuses = opts.fetch(:status, [])
          statuses = [statuses] unless statuses.is_a?(Array)
          unless @listing.order && (statuses.empty? || statuses.include?(@listing.order.status.to_sym))
            if @listing.order
              logger.warn("Disallowing as order #{@listing.order.id} does not have status: #{statuses.join(', ')}")
              opts[:flash] = "#{opts[:flash]}.invalid_status.#{action_name}" if opts[:flash]
            else
              logger.warn("Disallowing as listing #{@listing.id} does not have an order")
              opts[:flash] = "#{opts[:flash]}.nil.#{action_name}" if opts[:flash]
            end
            disallow(opts)
          end
        end
      end

      def require_state(state, options = {})
        before_filter options do
          unless @listing.send("#{state}?")
            logger.warn("Disallowing as listing #{@listing.id} is not #{state}")
            redirect_to(listing_path(@listing))
          end
        end
      end

      def require_transitionable(transition, options = {})
        before_filter options do
          unless @listing.send("can_#{transition}?")
            logger.warn("Disallowing as listing #{@listing.id} is not #{transition}-able")
            redirect_to(listing_path(@listing))
          end
        end
      end
    end

    def buyer?
      logged_in? && @listing.bought_by?(current_user)
    end

    def seller?
      (logged_in? && @listing.sold_by?(current_user)) || (guest? && @listing.sold_by?(guest_user))
    end

    private

    def disallow(options = {})
      set_flash_message(:alert, options[:flash]) if options[:flash]
      if options[:redirect] == :listing
        return redirect_to(listing_path(@listing))
      else
        respond_unauthorized
      end
    end
  end
end
