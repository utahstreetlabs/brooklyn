$(document).ready(function(event) {
  $container = $('#contacts-container');
  $container.contactinviter({
    url: $container.data('contacts-path')
  });
  $('#invite-form').submit(function() {
    if (window.opener && window.opener.jQuery) {
      window.opener.jQuery(window.opener.document).trigger('contactsSelected', [$container.contactinviter('selectedEmails')]);
      window.close();
    }
    return false;
  });
});
