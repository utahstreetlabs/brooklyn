ab_test :logged_in_home_trending_normalized do
  description "Test two trending sorts in homepage"
  alternatives :original_1, :original_2, :normalize_1, :normalize_2
  metrics :trending_engagement
end
