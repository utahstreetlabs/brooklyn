(function ($) {
  function remoteFileupload(options) {
    options = $.extend(options, {
      always: function(event, data){
        $.jsend.createJsendHandler(this)(data.result);
      },
      dataType: 'json'
    });
    return this.fileupload(options);
  };

  $.fn.remoteFileupload = remoteFileupload;
})(jQuery);
