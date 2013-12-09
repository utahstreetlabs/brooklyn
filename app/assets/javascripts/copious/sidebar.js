/**
 *  Javascript for sidebar widgets
 */
jQuery(function($) {
  $('.replacing-actions').replacingActions();
  $('.rolling-actions').rollingActions();
  $('#who-to-follow a.follow, #who-to-follow-more a.follow').
    live('ajax:beforeSend', function(){
      $(this).addClass('disabled').click(function(){return false;}).text('Following...');
    }).
    live('jsend:success', function(){
      $(this).text('Following').addClass('following');
      $.track('who-to-follow-followed', {href: $(this).attr('href')});
    });
  $('#who-to-follow a.ra-remove').
    live('jsend:success', function(){
      $.track('who-to-follow-removed', {href: $(this).attr('href')});
    });

  $('a.disabled').
    click(function(){
      return false;
    });

  $('#invite-friends').on('facebook:publishStreamAllowed', "[data-role='invite']", function(){
    var $button = $(this);
    $.ajax(this.href, {
      type: $button.data('method'),
      success: function(){
        $button.text('Invitation sent').closest('li').addClass('invited');
        $button.removeClass('button, positive').css('margin-left, 38px');
        $button.css('color', '#38312F !important');
        $button.closest('li').delay(3000).css('background-color', '#FFFFFF');
        $button.prev(".invite-friends-text").css('color', "FCFCD2");
        $button.off('click').on('click', function() { return false; });
      },
      fail: function() {
        $button.text('Invite').closest('li').addClass('invite');
        $button.removeClass('disabled');
      },
      beforeSend: function() {
        $button.closest('li').delay(3000).css('background-color', '#85CECE');
        $button.addClass('disabled').click(function(){return false;}).text('Inviting...');
      }
    });
  });
  $('a.rep-remove').
    live('ajax:beforeSend', function(){
      $(this).closest('li').delay(3000).css('background-color', '#FCFCD2');
    });
  $('#invite-friends-more a.invite').
    live('jsend:fail', function() {
      $.closeOverlay();
    });
});
