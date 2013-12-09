jQuery(function($) {
  $(document).bind('shareClicked', function() {
    $('#continue').show();
    $.jsend.post($('#share-buttons').data('create-url'), {});
  });
});
