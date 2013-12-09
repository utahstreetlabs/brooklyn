ab_test :logged_in_home do
  description "Test feed vs. popular (trending) listings on the logged-in home page"
  alternatives :feed_1, :feed_2, :popular_1, :popular_2
  metrics :homepage_engagement
end
