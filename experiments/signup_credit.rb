ab_test :signup_credit do
  description "Test the effect of different signup credits on successful registration"
  alternatives :ten_for_50, :twenty_five_for_100
  metrics :registrations
end
