module GatekeeperHelper
  # Sets up gatekeeper so we can have code execute only once it's completed loading.
  def gatekeeper_js
    content_tag(:div, '', id: 'gatekeeper-root') +
     javascript_tag(<<GKJS
(function(d, s, id) {
  window.COPIOUSGK = { apiInitialized: false, postInitQueue: [] };
  window.COPIOUSGK.postInit = function(callback) { window.COPIOUSGK.postInitQueue.push(callback) };
}(document, 'script', 'gatekeeper-js'));
GKJS
)
  end
end
