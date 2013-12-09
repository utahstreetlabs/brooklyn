jQuery(function($) {
  $('a.share').click(function() {
    var invite = window.open(this.href, 'shares-section', 'height=450,width=550');
    if (window.focus) { invite.focus(); }
    $(document).trigger('shareClicked');
    return true;
  });
});
