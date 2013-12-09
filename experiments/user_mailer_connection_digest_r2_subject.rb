ab_test :user_mailer_connection_digest_r2_subject do
  description "Test connection digest email subjects"
  alternatives 'weekly_digest', 'latest'
  metrics :cdigest_clickthroughs
end
