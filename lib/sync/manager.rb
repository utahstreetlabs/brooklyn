module Sync
  class Manager
    class << self
      def configure(config)
        config.marshal_dump.each do |type,settings|
          type_class = type.to_s.camelize
          if Sync.const_defined?(type_class)
            mod = Sync.const_get(type_class)
            mod.active_sources = settings.active_sources.map do |key|
              clazz = mod.const_get(key.to_s.camelize)
              settings.send(key).marshal_dump.each { |k,v| clazz.send("#{k}=", v) }
              clazz
            end
          end
        end
      end
    end
  end
end
