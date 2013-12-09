(function($) {
  /**
   * Represents an individual tag card widget. Composed of the card container itself and a contained like/unlike
   * remote link "button". When the button's background request completes successfully, updates the state of the card
   * and the contained button and triggers a +tagCard:liked+ event on the widget.
   */
  $.widget("copious.tagCard", {
    options: {
    },

    _create: function() {
      var $card = this;

      $card._initLikeButton();

      $card.likeButton.live('jsend:success', function(event, data) {
        if (data.button != undefined) {
          $card.updateLikeButton(data.button);
        }
        if (data.liked != undefined) {
          $card.updateCard(data.liked);
          $card.element.trigger('tagCard:liked', [data.liked]);
        }
      });
    },

    _initLikeButton: function() {
      var $card = this;
      $card.likeButton = $('.like-button', $card.element);
      $.remoteLink.initRemoteLink($card.likeButton);
    },

    /**
     * Replaces the like button's HTML with that provided.
     */
    updateLikeButton: function(html) {
      var $card = this;

      $card.likeButton.replaceWith(html);
      $card._initLikeButton();
    },

    /**
     * Updates the display of the card itself.
     */
    updateCard: function(liked) {
      var $card = this;

      if (liked) {
        $card.element.addClass('liked');
      } else {
        $card.element.removeClass('liked');
      }
    }
  });
})(jQuery);
