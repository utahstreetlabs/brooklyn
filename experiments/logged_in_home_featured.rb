ab_test :logged_in_home_featured do
  description "Test popular (trending) listings vs. featured listings on the logged-in home page"
  alternatives :popular_1, :popular_2, :featured_1, :featured_2
  metrics :homepage_engagement
end
