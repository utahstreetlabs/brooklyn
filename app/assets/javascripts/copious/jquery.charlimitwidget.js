(function($) {
  $.widget("copious.charlimit", {
    options: {},

    _init: function() {

      this.maxlength  = this.element.attr('maxlength');
      this.counterId = 'counter-for-' + this.element.attr('id');
      var counterStr = '<span class="char-limit-holder"> <span class="char-limit-number" id="' + this.counterId +
        '">';
      counterStr += this.element.val().length + '</span>';
      counterStr += '/ ' + this.maxlength + '</span>';

      this.element.after(counterStr);
      this.counter =  $('#' + this.counterId);

      var that = this;
      this.element.bind('input propertychange', function() {
        that.updateCounter($(this).val().length);
      });
    },

    updateCounter: function(length) {
      this.counter.html(length);
    }
  })
})(jQuery);
