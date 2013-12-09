//= require copious/jsend

jQuery.remoteLink = {
  /*
   * Initializes a remote link. This is an anchor element with the data-remote attribute set to "true".
   */
  initRemoteLink: function(element) {
    var $originalLink = $(element);
    // If element is a string, use "live" to bind the event to all
    // matching elements, now or in the future. If element is not a
    // string, live won't work, so use bind.
    var bind = $.proxy((typeof element == 'string')? $originalLink.live : $originalLink.bind, $originalLink);

    // Before handler for remote links - clears the form's error state
    bind('ajax:before', function(event) {
      copious.flash.clear();
      return true;
    });

    bind('ajax:beforeSend', function(event, xhr, settings) {
      if ($originalLink.data('include-source')) {
        params = {source: copious.source($originalLink), page_source: copious.pageSource()}
        settings.url = $.url.extend(settings.url, params)
      }
    });

    // Success handler for remote links - interprets the response data as a JSend envelope
    bind('ajax:success', $.jsend.createJsendEventHandler());

    // Error handler for remote links - sets a flash message
    bind('ajax:error', function(event, xhr, status, error) {
      debug.log("Ajax error [" + status + "]: " + error);
      copious.flash.alert("There was an error talking to the server. Please try again.");
    });

    // JSend success handler - sets a flash message if one is included
    bind('jsend:success', function(event, data) {
      var $link = $(event.currentTarget)
      if (data.message) { copious.flash.notice(data.message); }
      if (data.refresh) {
        var target = $link.data('refresh');
        if (target == 'self') {
          $newLink = $(data.refresh)
          $link.replaceWith($newLink)
          $newLink.trigger('remotelink:refresh');
          // if we aren't using live binding above, unbind event
          // handlers on the old link and initRemoteLink on the new
          // stuff. pretty nasty - need to drop this manual
          // instantiation business.
          if (! typeof element == 'string'){
            $link.off()
            $.remoteLink.initRemoteLink($newLink)
          }
        } else if (target){
          var $target = $(target)
          $target.html(data.refresh);
          $target.trigger('remotelink:refresh');
        } else {
          debug.log("Refresh target " + target + " not found");
        }
      }
      if (data.alert) {
        copious.bootstrapAlert.notice(data.alert);
      }
    });

    // JSend fail handler - sets a flash message if a flash message is included;
    bind('jsend:fail', function(event, data) {
      if (data.message) { copious.flash.alert(data.message); }
    });

    // JSend error handler - sets a flash message
    bind('jsend:error', function(event, message, code, data) {
      debug.log("JSend error [" + (code || '-') + "]: " + message);
      copious.flash.alert("There was an error talking to the server. Please try again.");
    });

    return $originalLink;
  }
};

jQuery(function ($) {
  // XXX: this actually only initializes the first element matching each selector. it really should initialize each.
  // however, that was breaking remote links all over the site - follow, block, invite etc. we really need a concerted
  // effort to refactor all of our remote links to dry them up and use the same conventions for data attributes and
  // jsend data structures.
  $.remoteLink.initRemoteLink('.remote-link');
  $.remoteLink.initRemoteLink('[data-link=remote]');
  $('[data-link=multi-remote]').each(function() { $.remoteLink.initRemoteLink(this) });
});
