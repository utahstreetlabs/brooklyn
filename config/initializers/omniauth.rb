require 'omniauth'

Dir[File.dirname(__FILE__) + '/../../lib/omniauth/strategies/*.rb'].each {|file| require file }

Rails.application.config.middleware.use OmniAuth::Builder do
  ssl_opts = if File.exists?('/etc/ssl/certs')
    {ca_path: '/etc/ssl/certs'}
  elsif File.exists?('/opt/local/share/curl/curl-ca-bundle.crt')
    {ca_file: '/opt/local/share/curl/curl-ca-bundle.crt'}
  end
  client_opts = {ssl: ssl_opts || {}}

  [Network::Facebook, Network::Twitter, Network::Tumblr,
   Network::Instagram, Network::Instagram::Secure].each do |network|
    if network.active?
      options = {setup: true, client_options: client_opts}.merge(network.omniauth_options)
      provider network.omniauth_provider, network.app_id, network.app_secret, options
    end
  end
end
