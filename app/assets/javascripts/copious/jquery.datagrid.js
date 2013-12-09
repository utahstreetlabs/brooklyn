/**
 * A component presenting a tabular view of data that supports a number of interactive features.
 * Assumes the following that the widget element is a form enclosing a table of data.
 *
 * Select/deselect all:
 * Requires the "toggle all" control checkbox to be given the class "datagrid-toggle-all".
 * Requires any toggleable checkbox to be given the class "datagrid-toggle".
 *
 * To come: sorting, paging, searching, filtering
 */
(function($) {
  $.widget("copious.datagrid", {
    options: {
      _form: null,
      _toggler: null
    },

    _init: function() {
      var $datagrid = this;

      $datagrid.options._form = this.element;
      $datagrid.options._toggler = $('input[type=checkbox].datagrid-toggle-all', $datagrid.options._form).
        filter(':first');

      // select/deselect all handler
      $datagrid.options._toggler.bind('change', function() {
        if ($datagrid.options._toggler.is(':checked')) {
          $datagrid._toggles().attr('checked', true);
        } else {
          $datagrid._toggles().attr('checked', false);
        }
      });
    },

    _toggles: function() {
      return $('input[type=checkbox]:not([disabled=disabled]).datagrid-toggle', this.options._form);
    },

    addToggleParams: function(url, key) {
      var toggles = this._toggles().filter(':checked');
      var mapped = $.map(toggles, function(toggle) { return key + '=' + encodeURIComponent($(toggle).val()) });
      if (mapped.length > 0) {
        var sep = url.indexOf('?') >= 0 ? '&' : '?';
        return url + sep + mapped.join('&');
      } else {
        return url;
      }
    }
  });
})(jQuery);
