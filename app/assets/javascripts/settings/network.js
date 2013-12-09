jQuery(function($) {

  function resetAutoshareForms() {
    for (i = 0; i < document.forms.length; i++) {
      document.forms[i].reset();
    }
  }

  var $autoshare = $("[data-role='autoshare-content']");

  $(document).on('facebook:connectCancelled', function() {
    resetAutoshareForms();
    copious.flash.notice("Your Facebook timeline settings have not been updated.");
  });

  $(document).on('facebook:connectComplete', function() {
    // Disable autoshare so we bypass going through the auth flow.
    $button = $("[data-role='autoshare-content'] [data-role='autoshare-save']");
    $button.addClass('checkedMissing');
    $button.click();
  })

  $(document).on('facebook:connectFailed', function() {
    resetAutoshareForms();
    copious.flash.alert("Oops!  We were unable to save your Facebook autosharing settings.  Try again?")
  })

  // Auth flow for facebook timeline permissions
  $("[data-role='autoshare-content'] [data-role='autoshare-save']").on('click', function() {
    // autoshare is populated if permissions are missing and we need
    // to send the user through the auth flow
    var $this = $(this);
    if ($this.hasClass('checkedMissing')) { return true; }
    $.jsend.get($autoshare.data('timeline-permission-url')).then(function(response) {
      copious.flash.clear();
      if(response.missing) {
        // Update our preferences so that we disable the timeline feature,
        // which will also prevent all autoshare options from being turned on.
        $.jsend.put($autoshare.data('timeline-disable-url')).
          then(function() {
            // When connect is complete, go ahead and update the settings.
            var connect = window.open($autoshare.data('auth-path'), 'autoshare-content', 'height=450,width=1000');
            if (window.focus) { connect.focus(); }
          });
      } else {
        $this.addClass('checkedMissing');
        $this.click();
      }
    });
    return false;
  });
});
