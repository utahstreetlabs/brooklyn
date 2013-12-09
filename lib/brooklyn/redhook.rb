require 'redhook'

module Brooklyn
  class Redhook
    class << self
      attr_accessor :person, :connection

      def async_create_person(person_id)
        # person.async_create(person_id)
      end

      def find_person(person_id)
        person.find(person_id)
      end

      def async_create_connection(source_id, sink_id, type)
        #connection.async_create(source_id, sink_id, type)
      end

      def async_destroy_connection(source_id, sink_id, type)
        #connection.async_destroy(source_id, sink_id, type)
      end

      def find_connections(source_id, sink_ids)
        #connection.find(source_id, sink_ids)
      end
    end
  end

  class NoWritePerson
    def self.async_create(*args); end
  end

  class NoWriteConnection
    def self.async_create(*args); end
    def self.async_destroy(*args); end
  end

  module RedhookTest
    class Person < NoWritePerson
      def self.find(person_id)
        nil
      end
    end

    class Connection < NoWriteConnection
      def self.find(*args)
        {}
      end
    end
  end

  module RedhookStub
    class Person < NoWritePerson
      def self.find(person_id)
        ::Redhook::Person.new({"person_id" => person_id, "total_connections" => 123,
          "typed_connections" => [116, 13, 0, 0, 0, 0, 0]})
      end
    end

    class Connection < NoWriteConnection
      def self.find(source_id, sink_ids)
        sink_ids[0..2].each_with_object({}) do |id,connections|
          connections[id] = {signal: 4, paths: [[::Redhook::Hop.new({'id' => id, 'types' => [:facebook_friend]})]]}
        end
      end
    end
  end
end
