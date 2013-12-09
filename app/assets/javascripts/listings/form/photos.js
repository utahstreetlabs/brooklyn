//= require jquery/jquery.iframe-transport
//= require jquery/jquery.fileupload
//= require jquery/jquery.endless-scroll
//= require copious/remote_fileupload
//= require copious/jquery.photoupload
//= require listings/photos/import
//= require copious/remote_form
//= require copious/modal_remote_form
//= require listings/photos/instagram_modal
//= require copious/aviary

// XXX: rewrite in coffeescript
// XXX: update bind/live/etc to use on
// XXX: it looks like everything related to ajax-overlay is obsolete. figure out what code and dependencies can be
// removed.

jQuery(function($) {
  // Photo uploading
  $('body').on('change', 'input.upload-computer', function() {
    $("[data-role='photo-list-section']").show();
    $('.btn-upload').addClass('uploading').loader();
  });
  $('#product-photos').photoupload();

  $(document).on('overlay:onBeforeLoad', function() {
    var header = $('#overlay-header');
    $(header).css('width', $('#ajax-overlay').width());
    $(header).css('top', $('#ajax-overlay').position().top);
    $(header).css('left', $('#ajax-overlay').position().left);

    var footer = $('#overlay-footer');
    $(footer).css('width', $('#ajax-overlay').width());
    $(footer).css('bottom', $('#ajax-overlay').position().bottom);
    $(footer).css('left', $('#ajax-overlay').position().left);
  });

  // Import from Instagram
  $('a.connect-instagram').live('click', function() {
    // When connect has finished, no longer have the connect-instagram class associated
    // with this element in case it's clicked again.
    var button = $(this);
    $(document).bind('connectComplete', function() {
      button.hide();
      $('.upload-instagram').show();
    });
    var connect = window.open($('#import-buttons').data('auth-path'), 'import-section', 'height=450,width=750');
    if (window.focus) { connect.focus(); }
    $(document).trigger('connectClicked');
    return false;
  });

  $('.ajax-overlay-trigger').bind('onLoad', function() {
    var trigger = this;
    $('#ajax-overlay').endlessScroll({
      bottomPixels: 50,
      fireOnce: false,
      fireDelay: 100,
      callback: function(i) {
        var $spinner = $('.loading-overlay-holder');
        var $more = $('.instagram-photos-more');
        if ($more && ($more.attr('fired') !== 'true')) {
          $more.attr('fired', true);
          $spinner.show();
          $.ajax({
            url: $more.attr('href'),
            dataType: 'json',
            success: function(json){
              var last_img = $("ul#instagram-photos li:last");
              $.each(json.data['results'], function(j,item){
                last_img.after($(item.ui));
                last_img = $("ul#instagram-photos li:last");
              });
              $more.attr('href',json.data['more']);
              $more.attr('fired', false);
              $spinner.hide();
            }
          });
        }
      }
    });
  });

  $('a.upload-computer').live('click', function() {
    $("[data-role='photo-list-section']").show();
    return false;
  });

  $('a.import').
    live('jsend:success', function(event, jsend) {
      $(this).text('Imported').addClass('done').closest('li').addClass('imported');
      $('.fileupload').trigger('jsend:success', jsend);
    }).
    live('ajax:beforeSend', function(){
      $(this).addClass('disabled').click(function(){return false;}).text('Importing...');
      $('.btn-upload').addClass('uploading').loader();
    });
});
