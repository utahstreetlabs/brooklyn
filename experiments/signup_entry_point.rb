ab_test :signup_entry_point do
  description "Test signup modal entry point vs Facebook OAuth dialog entry point"
  alternatives :signup_modal_1, :signup_modal_2, :fb_oauth_dialog_1, :fb_oauth_dialog_2
  metrics :network_connections
end
