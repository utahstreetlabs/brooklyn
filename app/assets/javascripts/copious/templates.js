(function($) {
  $.compileTemplate = function(id) {
    return Handlebars.compile($(id).html());
  }
})(jQuery);
