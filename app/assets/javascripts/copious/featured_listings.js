(function($) {
  $.widget("copious.featured_listings", {
    options: {},

    _init: function() {
      this._setup();
    },

    _setup: function() {
      var widget = this;
      var $list = $('.featured-listings-list', this.element);
      $list.sortable().
        live('sortupdate', function(event, ui) {
          $(this).trigger('reorder-to', [ui.item, $list.find('li').index(ui.item) + 1]);
        }).
        live('reorder-to', function(e, item, position) {
          $.jsend.post(item.data('reorder-url'), {position: position}).
            then(function(jsend) { widget._update(jsend.result); });
        });
    },

    _update: function(data) {
      this.element.html(data);
      this._setup();
    }
  });

  $('[data-role=featured-listings]').featured_listings();
})(jQuery);
