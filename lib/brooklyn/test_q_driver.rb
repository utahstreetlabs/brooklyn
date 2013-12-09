require 'resque'

module Brooklyn
  class TestQDriver
    class << self
      # simulate the stringification that happens in resque
      def jobify_args(args)
        ActiveSupport::JSON.decode(args.to_json)
      end

      def enqueue(job, *args)
        job.perform(*jobify_args(args)) if Resque.inline?
      end

      def enqueue_in(*args)
      end

      def enqueue_at(*args)
      end

      def enqueue_to(*args)
      end
    end
  end
end
