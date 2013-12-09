module ABHelper
  def ab_a?(name)
    value = ab_test(name, [true, false]) || Rails.env.test? || Rails.env.integration?
    if block_given?
      yield value
    else
      value
    end
  end

  def ab_b?(name)
    not ab_a?(name)
  end
end
