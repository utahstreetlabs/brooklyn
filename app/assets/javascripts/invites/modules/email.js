jQuery(function($) {
  $(document).bind('contactsSelected', function(event, contacts) {
    var addresses = $('.email-addresses');
    var currentAddresses = [];
    if (addresses.val()) currentAddresses.push(addresses.val());
    addresses.val(currentAddresses.concat(contacts).join(', '));
  });

  $('.contact-import').click(function() {
    var contactImport = window.open(this.href, 'contact-import', 'height=500,width=1020');
    if (window.focus) { contactImport.focus(); }
    return false;
  });
});
