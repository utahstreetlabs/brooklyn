/*
 * A widget providing an API for interacting with a listing's comment feed.
 */
$.widget('copious.listing_feed', {
  options: {
    _templates: {
      comment: {
        flag: null,
        reply: null
      },
      reply: {
        flag: null
      }
    }
  },

  /**
   * Initializes the feed. Compiles the flag and reply tray handlebars templates and initializes the comment entry box
   * and all comments.
   */
  _init: function() {
    var $feed = this;

    debug.log("initializing listing feed");

    $feed.options._templates.comment.flag = $.compileTemplate('#listing-comment-flag-template');
    $feed.options._templates.comment.reply = $.compileTemplate('#listing-comment-reply-template');
    $feed.options._templates.reply.flag = $.compileTemplate('#listing-reply-flag-template');

    $feed._initCommentEntry();

    $('.listing-feed-comment', $feed.element).each(function() {
      $feed._initComment($(this), 'comment');
    });
  },

  /**
   * Initializes the comment entry box. Assumes the entry box container is a +li+ element with id
   * +listing-feed-comment-entry+ and that it contains the comment entry form. Initializes that form as a remote form.
   * When the form submission is succesfully processed, constructs an +li+ element to represent the new comment,
   * inserts it in the feed +ul+ immediately after the comment entry box, and initializes the new comment.
   */
  _initCommentEntry: function() {
    var $feed = this;
    var $feedContainer = $feed.element;

    var $commentEntryContainer = $('#listing-feed-comment-entry');
    $.remoteForm.initRemoteForm($commentEntryContainer);

    var $commentEntryForm = $('form', $commentEntryContainer);
    $commentEntryForm.bind('jsend:success', function(event, data) {
      var html = '<li id="listing-feed-comment-' + data.commentId + '" class="listing-feed-comment" data-listing="' +
        data.listingId + '" data-comment="' + data.commentId + '">' + data.comment + '</li>';
      $feedContainer.prepend(html);

      // initialize the new comment, adding controls etc
      var $newCommentContainer = $feedContainer.children().first();
      $feed._initComment($newCommentContainer, 'comment');

      // clear the textarea, setting it back to its placeholder value, and cause it to lose focus
      $commentInput = $('#comment_text', $commentEntryContainer)
      $commentInput.val('');
      $commentInput.trigger('blur');
    });
  },

  /**
   * Initializes a comment. Initializes flag and reply trays, and initializes an action control for each +a+ element
   * in the comment container with the class +comment-action+.
   */
  _initComment: function($container, commentType) {
    var $feed = this;

    debug.log("initializing " + commentType + " for container " + $container.attr('id'));

    $feed._initTray($container, 'flag', commentType);
    if (commentType == 'comment') {
      $feed._initTray($container, 'reply', commentType);
    }

    $.each($('a.listing-feed-' + commentType + '-action', $container), function(index, control) {
      $feed._initAction($container, $(control), commentType);
    });

    if (commentType == 'comment') {
      $('.listing-feed-reply', $container).each(function() {
        $feed._initComment($(this), 'reply');
      });
    }
  },

  /**
   * Initializes a tray of a particular type. Expects the container to include an +a+ element with class
   * +listing-feed-comment-<trayType>+ to use as the toggle control for the container.
   */
  _initTray: function($container, trayType, commentType) {
    var $feed = this;

    debug.log("initializing " + trayType + " " + commentType + " tray for container " + $container.attr('id'));

    var $tray = $('.listing-feed-' + commentType + '-' + trayType + '-tray', $container);
    $tray.hide();

    var $control = $('a.listing-feed-' + commentType + '-' + trayType, $container);
    $control.click(function() {
      if ($feed._isTrayOpen($tray)) {
        $feed._closeTray($tray, $container, trayType, commentType);
      } else {
        $feed._openTray($tray, $container, trayType, commentType)
      }
      return false;
    });
  },

  /**
   * Returns the tray of a particular type if opened.
   */
  _isTrayOpen: function($tray) {
    return $tray.children().length > 0 ? $tray : null;
  },

  /**
   * Opens the tray of a particular type. Creates a +div+ element with class +listing-comment-<trayType>-tray+ with
   * contents given by rendering the template of type <trayType> and appends it to the contents of the element with
   * class +listing-feed-comment-text+ within the container. Initializes the remote form within the tray and
   * binds a success handler to re-render the comment or display a confirmation message depending on the results
   * from the server.
   */
  _openTray: function($tray, $container, trayType, commentType) {
    var $feed = this;
    var context = {
      listingId: $container.data('listing'),
      commentId: $container.data('comment'),
      replyId: $container.data('reply')
    };

    debug.log("opening " + trayType + " " + commentType + " tray for container " + $container.attr('id'));

    $tray.html($feed.options._templates[commentType][trayType](context));

    // rewrite the form's action. this is necessary because moustache can't recognize the url-escaped '{{commentId}}'.
    var $form = $('form', $tray);
    var action = $form.attr('action');
    action = action.replace(/:commentId/, context.commentId);
    action = action.replace(/:replyId/, context.replyId);
    $form
      .attr('action', action)
      .append($('<input>', {type: 'hidden', name: 'source', value: copious.source($form)}))
      .append($('<input>', {type: 'hidden', name: 'page_source', value: copious.pageSource()}));

    $.remoteForm.initRemoteForm($tray);
    $tray.bind('jsend:success', function(event, data) {
      if (data.confirmation) {
        debug.log("setting confirmation in container " + $container.attr('id'));
        $container.html('<p>' + data.confirmation + '</p>');
      } else if (data.comment) {
        debug.log("re-rendering comment in container " + $container.attr('id'));
        $container.html(data.comment);
        $feed._initComment($container, commentType);
      } else {
        $container.remove();
      }
    });

    $('a.listing-' + commentType + '-' + trayType + '-cancel', $tray).click(function() {
      $feed._closeTray($tray, $container, trayType, commentType);
      return false;
    });

    $tray.slideDown('fast', function() {
      $tray.css('overflow', 'visible');
    });

    return $tray;
  },

  /**
   * Closes the given tray.
   */
  _closeTray: function($tray, $container, trayType, commentType) {
    debug.log("closing " + trayType + " " + commentType + " tray for container " + $container.attr('id'));
    $tray.slideUp('fast', function() {
      $tray.html('');
    });
  },

  /**
   * Initializes an action control element as a remote link and binds a success handler to re-render the comment or
   * display a confirmation message depending on the results from the server.
   */
  _initAction: function($container, $control, commentType) {
    var $feed = this;

    debug.log('initializing ' + $control.text() + ' ' + commentType + ' action for container ' +
              $container.attr('id'));

    $.remoteLink.initRemoteLink($control);
    $control.bind('jsend:success', function(event, data) {
      if (data.confirmation) {
        debug.log("setting confirmation in container " + $container.attr('id'));
        $container.html('<p>' + data.confirmation + '</p>');
      } else if (data.comment) {
        debug.log("re-rendering comment in container " + $container.attr('id'));
        $container.html(data.comment);
        $feed._initComment($container, commentType);
      } else {
        $container.remove();
      }
    });
  }
});
