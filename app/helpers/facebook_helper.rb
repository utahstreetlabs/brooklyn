module FacebookHelper
  def facebook_auth_params(options = {})
    auth_params = {}
    auth_params[:seller_signup] = options[:seller_signup] if options[:seller_signup]
    auth_params[:scope] = options[:scope] if options[:scope]
    auth_params[:d] = options[:d] || request.fullpath
    params = {data: {action: "auth-facebook", primary: options.fetch(:primary, true)}}
    params[:data][:auth_url] = Network::Facebook.auth_callback_path(auth_params)
    params
  end

  # Load the FB js api
  #
  # As of 5/4/12, MUST be included immediately after open-body <body>
  # tag. Including it elsewhere appears to prevent the like button
  # from being instantiated properly.
  # However, since we are loading all.js asynchronously, there is no guarantee that our own facebook code will load
  # first.  Rather than dump a crazy pile of js at the top of every page, we manage the timing issue with a placeholder
  # function that just tells our facebook initializer about the sequencing.  The use of this code is in facebook.js.erb.
  # Using COPIOUSFB instead of COPIOUS so we don't need all the setup stuff from copious.js.erb
  def facebook_jssdk
    content_tag(:div, '', id: 'fb-root') +
      javascript_tag(<<FBJS
(function(d, s, id) {
  window.COPIOUSFB = { alreadyLoaded: false, apiInitialized: false, postInitQueue: [] };
  window.COPIOUSFB.initialize = function() { window.COPIOUSFB.alreadyLoaded = true; };
  window.COPIOUSFB.postInit = function(callback) { window.COPIOUSFB.postInitQueue.push(callback) };
  window.fbAsyncInit = function() { window.COPIOUSFB.initialize() };
  
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=#{Brooklyn::Application.config.networks.facebook.app_id}";
  js.async = true;
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
FBJS
                 )
  end
end
