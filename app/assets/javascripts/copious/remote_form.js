//= require copious
//= require copious/tracking
//= require controls/flash

jQuery(function ($) {
  $.remoteForm = {
    /*
     * Initializes an inline remote form. This is a block container of some sort embedding a form with the data-remote
     * attribute set to "true".
     */
    initRemoteForm: function(element) {
      var $element = $(element);
      var $form = $element.is('form') ? $element : $('form', $element);
      var $spinner = $('.loading-spinner', $form);

      // Before handler for remote form submissions - clears the form's error state
      $form.bind('ajax:before', function(event) {
        copious.flash.clear();
        $form.find('ul.errorlist').each(function() {
          var $errorlist = $(this);
          $errorlist.parent().removeClass('error');
          $errorlist.remove();
        });
        $spinner.show();
        if ($element.data('include-source')) {
          $form.
            append($('<input>').attr({type: 'hidden', name: 'source', value: copious.source($element)})).
            append($('<input>').attr({type: 'hidden', name: 'page_source', value: copious.pageSource()}))
        }
        return true;
      })

      $form.bind('ajax:complete', function(event) {
        $spinner.hide();
        if ($element.data('include-source')) {
          $form.find('[name=source],[name=page_source]').remove()
        }
      });

      // Success handler for remote form submissions - interprets the response data as a JSend envelope
      $form.on('ajax:success', $.jsend.createJsendEventHandler($form));

      // Error handler for remote form submissions - sets a flash message
      $form.on('ajax:error', $.remoteForm.showFlashOnAjaxError);

      // JSend success handler - sets a flash message if one is included
      $form.on('jsend:success', $.remoteForm.showFlashOnSuccess);

      // JSend fail handler - sets a flash message if a flash message is included
      $form.on('jsend:fail', function(event, data) {
        if (data.message) {
          copious.flash.alert(data.message);
        } else if (data.errors) {
          $.each(data.errors, function(field_name, msgs) {
            var $field = $('.field-' + field_name, $form);
            msgs = $.isArray(msgs) ? msgs : [msgs];
            var $ul = $('<ul class="errorlist"></ul>');
            $.each(msgs, function(index, msg) { $('<li>' + msg + '</li>').appendTo($ul) });
            $field.append($ul);
            $field.addClass('error');
          });
        }
      });

      // JSend error handler - sets a flash message and closes the inline
      $form.bind('jsend:error', $.remoteForm.showFlashOnJsendError);

      return $element;
    },

    showFlashOnSuccess: function(event, data) {
      if (data.message) { copious.flash.notice(data.message) }
    },

    showFlashOnAjaxError: function(event, xhr, status, error) {
      debug.log("Ajax error [" + status + "]: " + error);
      copious.flash.alert("There was an error talking to the server. Please try again.");
    },

    showFlashOnJsendError: function(event, message, code, data) {
      debug.log("JSend error [" + (code || '-') + "]: " + message);
      copious.flash.alert("There was an error talking to the server. Please try again.");
    }
  };
});
