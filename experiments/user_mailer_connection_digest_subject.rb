ab_test :user_mailer_connection_digest_subject do
  description "Test connection digest email subjects"
  alternatives 'latest_loves', 'style_scoop'
  metrics :cdigest_clickthroughs
end
