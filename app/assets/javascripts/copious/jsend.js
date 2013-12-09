(function ($) {
  function createJsendHandler(target){
    return function(jsend) {
      var $target = $(target || this);
      if (jsend.status == 'success') {
        $target.trigger('jsend:success', [jsend.data]);
      } else if (jsend.status == 'fail') {
        $target.trigger('jsend:fail', [jsend.data]);
      } else if (jsend.status == 'error') {
        $target.trigger('jsend:error', [jsend.message, jsend.code, jsend.data]);
      } else {
        debug.log("Unknown jsend status " + jsend.status);
      }
    };
  }

  function createJsendEventHandler(target){
    var f = createJsendHandler(target);
    return function(event, target){ f.call(this, target); };
  };

  function jsendDeferred(jqXHR){
    return $.Deferred(function(dfd){
      jqXHR.then(function(jsend, status, xhr){
        if (jsend.status == 'success'){
          dfd.resolveWith(xhr, [jsend.data]);
        } else {
          if (jsend.data) {
            debug.log("Remote application error [" + jsend.data.status + "]: " +jsend.data.error);
          }
          dfd.rejectWith(xhr, [jsend.status, jsend.data]);
        }
      },
      function(xhr, status){
        debug.log("XHR failure [" + status + "]");
        dfd.rejectWith(xhr, [status]);
      });
    }).promise();
  }

  function get(url, query, options){
    var args = {url: url, data: query, dataType: 'json'};
    if (typeof options !== undefined) { $.extend(args, options) }
    return jsendDeferred($.ajax(args));
  }

  function post(url, query){
    return jsendDeferred($.post(url, query, null, 'json'));
  }

  function put(url, query){
    return jsendDeferred($.ajax(url, {type: 'PUT', dataType: 'json', data: query}));
  }

  function del(url, query){
    return jsendDeferred($.ajax(url, {type: 'DELETE', dataType: 'json', data: query}));
  }

  function ajax(url, query, method, options){
    var args = {url: url, data: query, type: method, dataType: 'json'};
    options = $.extend(args, options);
    return jsendDeferred($.ajax(args));
  }

  $.jsend = {
    createJsendHandler: createJsendHandler,
    createJsendEventHandler: createJsendEventHandler,
    get: get,
    post: post,
    put: put,
    del: del,
    ajax: ajax,
    deferred: jsendDeferred
  };
})(jQuery);
