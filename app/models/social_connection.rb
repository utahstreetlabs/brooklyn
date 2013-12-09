class SocialConnection
  attr_reader :paths
  attr_reader :path_count
  attr_reader :signal

  def initialize(redhook_connection={paths: []})
    @signal = redhook_connection[:signal]
    @redhook_paths = redhook_connection[:paths]
    @path_count = redhook_connection[:count]
  end

  def shared_count
    path_count
  end

  # memoize +paths+ instead of determining it at initialization because it's an expensive method and there are
  # places where we don't use the value (such as connection summaries in listings browse)
  def paths
    @paths ||= load_paths
  end

  def load_paths
    # get the ids so we can make a single db call
    person_ids = @redhook_paths.inject(Set.new) do |ids, path|
      ids.add(path[0].id).add(path[-1].id)
    end
    person_cache = Person.where(:id => person_ids.to_a).includes(:user).inject({}) do |map, person|
      map.merge(person.id => person)
    end
    @redhook_paths.map {|p| Path.new(person_cache[p[0].id], person_cache[p[-1].id], p)}.
      reject {|p| p.adjacent.nil? or p.other.nil?}
  end

  # find the connections between the first user and all others passed in
  # returns a hash with the person_id as the key and the connection as the value
  def self.all(source_user, sink_users)
    sink_ids = sink_users.map { |u| u.person_id }
    Rails.logger.debug("Loading connections between person #{source_user.person_id} and people #{sink_ids}")
    Brooklyn::Redhook.find_connections(source_user.person_id, sink_ids).each_with_object({}) do |(k,v),h|
      h[k] = self.new(v)
    end
  end

  # convenience method for single connection lookup
  def self.find(source_user, sink_user)
    self.all(source_user, [sink_user]).values.first
  end

  class Path
    attr_reader :adjacent
    attr_reader :other
    attr_reader :types

    def initialize(adjacent, other, redhook_path)
      @other = other
      @adjacent = adjacent
      # in order to describe the path, we take the first (highest signal) type from each step
      @types = redhook_path.map { |h| h.types[0] }
    end

    def direct?
      @types.length == 1
    end
  end
end
