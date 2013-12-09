# A class encapsulating the structure we pack into the facebook ref parameter
#
# see
#
# http://developers.facebook.com/docs/opengraph/actions/
#
# for more information on the structure Facebook imposes. We add more
# structure to the "right side" of the ref parameter. It will be passed
# to facebook as a base64 encoded JSON hash created from the +data+
# attribute of Ref, and can be used to store arbitrary data that we
# would like to associate with facebook clickthroughs.
#
class Network::Facebook::Ref
  attr_reader :insights_tags, :data

  def initialize(insights_tags, data = {})
    self.insights_tags = insights_tags
    self.data = data
  end

  def insights_tags=(tags)
    @insights_tags = Array.wrap(tags)
  end

  def data=(data)
    raise ArgumentError if data && !data.is_a?(Hash)
    @data = data || {}
  end

  def ==(other)
    (self.insights_tags == other.insights_tags) && (self.data == other.data)
  end

  def to_ref
    return nil if @insights_tags.empty? && (@data.nil? || @data.empty?)
    r = "#{@insights_tags.join(',')}"
    r << "__#{Base64.urlsafe_encode64(ActiveSupport::JSON.encode(@data))}" if @data and @data.any?
    r
  end

  def self.from_ref(ref)
    (insights, data) = ref.split('__') if ref
    Network::Facebook::Ref.new(parse_tags(insights), parse_data(data))
  end

  def self.parse_data(data)
    if data
      begin
        ActiveSupport::JSON.decode(Base64.urlsafe_decode64(data)).symbolize_keys
      rescue Exception => e
        raise ArgumentError.new("Could not parse #{data}, failed with error #{e}")
      end
    end
  end

  def self.parse_tags(tags)
    return [nil, nil] if tags == ','
    tag_string = (tags || '')
    parsed = tag_string.split(',').map {|v| v.present?? v : nil}
    parsed << nil if tag_string.last == ','
    parsed
  end
end
