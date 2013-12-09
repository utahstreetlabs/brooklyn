jQuery(function($) {
  $(document).bind('connectComplete', function() {
    $('#continue').click();
  })

  $(document).bind('connectFailed', function() {
    copious.flash.alert("Oops!  Could not connect to network with that account.  Try another?")
  })
});
