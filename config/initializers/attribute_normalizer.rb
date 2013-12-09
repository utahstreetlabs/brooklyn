AttributeNormalizer.configure do |config|
  config.normalizers[:currency] = lambda do |value, options|
    return nil if value.nil?
    value.is_a?(String) ? value.gsub(/[^0-9\.]+/, '').to_d : value.to_d
  end

  config.normalizers[:integer] = lambda do |value, options|
    return nil if value.nil?
    value.to_i
  end

  config.normalizers[:boolean] = lambda do |value, options|
    value.is_a?(String) ? (value == "1" || value == "true") : (value == 1 || value == true)
  end

  # ensure that blanks are converted to null
  config.normalizers[:null_blank] = lambda do |value, options|
    (value.is_a?(String) and not value.present?) ? nil : value
  end

  config.normalizers[:credit_card] = lambda do |value, options|
    value.present? ? value.gsub(/[^0-9]+/, '') : nil
  end
end
