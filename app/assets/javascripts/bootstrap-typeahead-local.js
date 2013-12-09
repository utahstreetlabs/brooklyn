/* =============================================================
 * bootstrap-typeahead-local.js
 * =============================================================
 * This library overrides the defaults in bootstrap-typeahead.
 * bootstrap-typeahead must be included before this one, or
 * it will fail.
 * ============================================================ */

!function( $ ) {

  "use strict"

  var Typeahead = $.fn.typeahead;

  Typeahead.prototype = $.extend($.fn.typeahead.Constructor.prototype, {

    constructor: Typeahead,

    //Resets select back to original state.
    select: function () {
      var val = this.$menu.find('.active').attr('data-value')
      this.$element
        .val(this.updater(val))
        .change()
      return this.hide()
    },

    //Adds startWith to typeahead lib.  Adds a string to the items list.
    render: function (items) {
      var that = this

      items = $(items).map(function (i, item) {
        i = $(that.options.item).attr('data-value', item.replace(that.options.startWith, ""))
        i.find('a').html(that.highlighter(item))
        return i[0]
      })

      items.first().addClass('active')
      this.$menu.html(items)
      return this
    },

    //Sorts typeahead list.  Prefixs dropdown list w/ a string.
    sorter: function (items) {
      var beginswith = []
        , caseSensitive = []
        , caseInsensitive = []
        , item

      //deep copy options, append to param
      if(this.options.startWith.length && this.query.length > 1){
        beginswith = this.options.startWith.slice(0)
        beginswith[0] += this.query
      }

      while (item = items.shift()) {
        if (!item.toLowerCase().indexOf(this.query.toLowerCase())){
          if(this.query.toLowerCase() == item.toLowerCase()){
            //Remove begins with, if query matches item.
            beginswith = []
          }
          beginswith.push(item)
        }
        else if (~item.indexOf(this.query)){
          caseSensitive.push(item)
        }
        else {
          caseInsensitive.push(item)
        }
      }

      return beginswith.concat(caseSensitive, caseInsensitive)
    }
  })

  $.fn.typeahead.defaults = $.extend($.fn.typeahead.defaults, { startWith: [] })

  $.fn.typeahead.Constructor = Typeahead

}( window.jQuery )