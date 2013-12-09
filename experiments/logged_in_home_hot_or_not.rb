ab_test :logged_in_home_hot_or_not do
  description "Test home page engagement for users with hot or not enabled vs those without it"
  alternatives :on_1, :on_2, :off_1, :off_2
  metrics :homepage_engagement
end
