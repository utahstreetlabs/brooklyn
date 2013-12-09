jQuery(function($) {
  var $timeline = $("[data-role='timeline-content']");
  var $timelineForm = $('form', $timeline);
  $.remoteForm.initRemoteForm($timeline);

  $(function() {
    $("[data-role='decline-timeline']").click(function() {
      $('.top-message').hide();
      $timelineForm.submit();
      return false;
    });
  });
});
