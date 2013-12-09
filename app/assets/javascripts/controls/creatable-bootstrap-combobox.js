//= require bootstrap-combobox

/**
 * Custom overrides of the bootstrap combobox to allow the creation of new entries and remote fetch of values.
 **/
(function($) {
  /**
   * Default behavior for pressing ENTER inside a combobox appears to be submitting the form.  That just ain't right.
   **/
  var originalKeyPress = $.fn.combobox.Constructor.prototype.keypress;
  $.fn.combobox.Constructor.prototype.keypress = function(event) {
    // 13 = enter.  By default, it's submitting the page, even when the text field has focus.  So just block it.
    if (event.which == 13) {
      return false;
    }
    return $.proxy(originalKeyPress, this)(event);
  }

  /**
   * Call the built-in sorter (alphabetical), then check the result for our custom "Add blah" entry and move it to the
   * top.
   **/
  var originalSorter = $.fn.combobox.Constructor.prototype.sorter;
  $.fn.combobox.Constructor.prototype.sorter = function(items) {
    var sorted = $.proxy(originalSorter, this)(items);
    var index = -1;
    var prefix = this.options.createPrefix;
    if (prefix && prefix.length > 0) {
      $.each(sorted, function(i, item) {
        if (0 == item.indexOf(prefix)) {
          index = i;
          // stop iteration if we found it
          return false;
        }
      });
      if (index > 0) {
        var first = sorted.splice(index, index);
        return first.concat(sorted);
      }
    }
    return sorted;
  }

  /**
   * More handling of our custom 'Add blah' entry.  We trap the select call and in the case that the special
   * entry was selected, convert into a normal entry containing the current value so that it will function
   * properly.
   **/
  var originalSelect = $.fn.combobox.Constructor.prototype.select;
  $.fn.combobox.Constructor.prototype.select = function() {
    var prefix = this.options.createPrefix;
    if (prefix && prefix.length) {
      var active = this.$menu.find('.active'),
          val = active.attr('data-value');

      if (0 == val.indexOf(prefix)) {
        // NB: i considered using `this.$element.val()` instead of stripping the prefix, but
        // that value is not present after a click because the combobox assumes you've only typed some portion of a
        // word and it needs to replace it with the full one you selected.
        val = val.substring(prefix.length);
        this.$target.children("[data-role='create']").removeAttr('data-role').html(val);
        active.attr('data-value', val);
        this.refresh();
      }
    }
    $.proxy(originalSelect, this)();
  }

  /**
   * The `lookup` function is used to find typeahead matches for the current text.  We modify the behavior in two
   * ways:
   * 1) We inject a 'create' option (ie. 'Add blah') into the select list to allow the user to click to create
   *    a new entry.
   * 2) We do a remote lookup for more matches if there are more than 2 chars in the field (the initial query only
   *    loads a subset of options, currently 100).
   **/
  var originalLookup = $.fn.combobox.Constructor.prototype.lookup;
  $.fn.combobox.Constructor.prototype.lookup = function(event) {
    var query = this.$element.val();

    // insert the "Add blah" option at the top if creation is allowed and the query exists
    // we only insert one option, and then manipulate it (or remove it) as the text in the query changes
    var $create = this.$target.children("[data-role='create']");
    if (this.options.allowCreate) {
      if (query.length > 0 && !this.map[query]) {
        if (0 == $create.length) {
          // jquery `.data` failing to work in my browser.  can't explain.
          $create = $('<option>').attr('data-role', 'create');
          // keep this second in the list, after the blank option
          this.$target.children(':first-child').after($create);
        }
        $create.val(query).html(this.options.createPrefix + query);
      } else if ($create.length > 0) {
        $create.remove();
      }
    }

    // if there are more than 2 chars in the query, fetch any remote matches and add them to the select list
    // since the original set in the list was limited to a subset
    if (query.length > 1) {
      $.jsend.get(this.options.lookAheadSource, {query: query}).then($.proxy(function(response) {
        $.each(response.options, $.proxy(function(i, option) {
          if (!this.map[option.name]) {
            $option = $('<option>').val(option.slug).html(option.name);
            this.$target.append($option).val(option.val);
          }
        }, this));
        this.refresh();
        $.proxy(originalLookup, this)(event);
      }, this));
    } else {
      // only call this one if it won't be happening in the callback.
      this.refresh();
      return $.proxy(originalLookup, this)(event);
    }
  }
})(jQuery);
