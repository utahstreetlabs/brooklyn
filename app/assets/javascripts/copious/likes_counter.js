(function($) {
  /**
   * Represents the "likes counter" widget. Composed of a button and a two-part label that are rendered differently
   * depending on how many tags have been liked - if the required number (or more) has been liked, the widget is
   * placed into the "done" and the button is enabled; otherwise, the button is disabled.
   */
  $.widget("copious.likesCounter", {
    options: {
      requiredCount: 5
    },

    _create: function() {
      var $counter = this;

      $counter.labelElement = $('.likes-counter', $counter.element);
      $counter.countElement = $('.likes-counter-count', $counter.labelElement);
      $counter.buttonElement = $('.likes-counter-button', $counter.element);
      $counter.count = $counter.element.data('count');
      $counter.requiredCount = $counter.options.requiredCount;
    },

    /**
     * This function should be called when a tag is liked or unliked. The single parameter is a boolean that describes
     * whether or not the tag was liked.
     */
    update: function(liked) {
      var $counter = this;

      if (liked) {
        $counter.count++;
      } else {
        $counter.count--;
      }

      if ($counter.count >= $counter.requiredCount) {
        $counter.labelElement.addClass('done');
        $counter.countElement.text(0);
        $counter.buttonElement.removeClass('disabled');
      } else {
        $counter.labelElement.removeClass('done');
        var more = $counter.requiredCount - $counter.count;
        $counter.countElement.text(more);
        $counter.buttonElement.addClass('disabled');
      }
    }
  });
})(jQuery);
