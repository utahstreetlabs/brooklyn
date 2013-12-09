module Brooklyn
  module ABTesting
    extend ActiveSupport::Concern
    delegate :experiment_active?, :latest_active_experiment, to: 'self.class'

    module ClassMethods
      def latest_active_experiment(experiment_name)
        Vanity.playground.experiments.keys.sort.reverse.find do |k|
          k.to_s.starts_with?(experiment_name.to_s)
        end
      end

      # Returns true if the named experiment is active, false otherwise.
      #
      # Note that calling this for a non-existent experiment will return
      # false.
      #
      # Experiment names are prefix-matched against all active experiments, so
      # experiment_active?(:ham) will return true if there is an active experiment
      # named :ham or :ham2 or :hamburgers
      #
      # @param [Symbol] experiment_name the name of the experiment in question
      def experiment_active?(experiment_name)
        !!Vanity.playground.experiments[experiment_name.to_sym]
      end

      def variant_for_experiment(visitor_id, experiment_name)
        redis = Vanity.playground.connection.redis
        begin
          redis.keys("vanity:experiments:#{experiment_name}:alts:*:participants").each do |key|
            return variant_for_key(key) if redis.sismember(key, visitor_id)
          end
        rescue Exception => e
          logger.error("Exception: #{e} getting variant for visitor_id: #{visitor_id}, experiment: #{experiment_name}.")
        end
        nil
      end

      def variant_for_key(key)
        tokens = key.split(':')
        if tokens.length > 4
          alt = tokens[4].to_i
          experiment_name = tokens[2].to_sym
          Vanity.playground.experiments[experiment_name].alternatives[alt].value
        else
          nil
        end
      end
    end
  end
end
