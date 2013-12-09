def model_error(attr, key, options = {})
  I18n.translate("activerecord.errors.models.user.attributes.#{attr}.#{key}", options)
end


def order_with_handling_time(handling_duration)
  order = Factory.create(:confirmed_order)
  l = order.listing
  l.handling_duration = handling_duration
  l.save!
  order
end

def addresses_should_match(addr1, addr2)
  addr1.should be_a(PostalAddress)
  addr2.should be_a(PostalAddress)
  addr1.attributes.keys.map(&:to_sym).delete_if {|k| [:id, :created_at, :updated_at, :order_id].include?(k)}.each do |k|
    addr1.send(k) == addr2.send(k)
  end
end

def freeze_time(time)
  around { |example| Timecop.freeze(time) { example.run }}
end

class String
  # This lets us pass either a string or an AR object to methods that build URLs
  # manually and call to_param on whatever we receive in those methods, avoiding
  # code like:
  #
  #    slug = collection.respond_to?(:to_param) ? collection.to_param : collection
  #
  # This pattern is useful when constructing URLs that should 404.
  def to_param
    self
  end
end
