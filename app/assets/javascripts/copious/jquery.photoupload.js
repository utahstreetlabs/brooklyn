(function($) {

  // We no longer show the photo (file) uploader if there's no photos
  // already uploaded; we have separate buttons that are always active.
  function updatePhotoUploader() {
    if($('.btn-photo').length > 1) {
      $("[data-role='photo-list-section']").attr('style', "");
      $("[data-role='photo-help-text-section']").attr('style', "");
    } else {
      $("[data-role='photo-list-section']").attr('style', "display: none");
      $("[data-role='photo-help-text-section']").attr('style', "display: none");
    }
  }

  // photo upload widget
  //
  // The photo upload widget creates a sortable list of photos and
  // a file upload widget.
  //
  // It currently works against a set of hardcoded classes:
  //   .photos - an element containing a list of sortable elements, an upload
  //             button, and remote links
  //   .sortable - an element containing a list of items that should be made
  //               sortable using the jquery sortable plugin. Each item in
  //               the list should have a reorder-url data parameter which will
  //               receive a POST upon reordering
  //   .photo-upload-button - an element which, when clicked, should trigger the
  //                          file upload dialog
  //
  // It will also set up any internal remote links and configure them to update
  // the contents of .photos when executed.
  //
  // All interactions currently expect to receive an updated version of the .photos
  // element upon success, embedded within a jsend response.
  //
  // TODO: stop hardcoding classes, support alternate ajax behaviors
  //
  $.widget("copious.photoupload", {
    options: {},

    _init: function() {
      var widget = this;
      this._setupPhotos();
      $(document.body).on('new-photos', function(e, data) { widget._updatePhotos(data)});

    },

    _setupPhotos: function(){
      var widget = this;
      var root = this.element;
      $('.fileupload', root).remoteFileupload({singleFileUploads: false}).
        bind('jsend:success', function(e, jsend){ widget._updatePhotos(jsend); });
      $.remoteForm.initRemoteForm($('.update-photo-form'));

      $('.sortable', root).sortable({
        axis: 'x',
        items: 'li:not(.upload)',
        cancel: '.btn-upload',
        update: function(event, ui){
          $(this).trigger('reorder-to', [ui.item, ui.item.parents('ul:first').find('li').index(ui.item) + 1]);
        }
      }).bind('reorder-to', function(e, item, position){
        $.jsend.post(item.data('reorder-url'), {position: position}).
          then(function(jsend) { widget._updatePhotos(jsend); });
      });
    },

    _updatePhotos: function(data){
      var widget = this;
      var f = $('.fileupload', this.element);
      $('.btn-upload', f).removeClass('uploading').html('');
      $('.photos', this.element).html(data.photos);
      $('.photo-update-forms').html(data.update);
      updatePhotoUploader();
      $.remoteForm.initRemoteForm($('.update-photo-form'));

      // Rebind everything, including new photos
      $.remoteLink.initRemoteLink($('a[data-remote=true]', '[data-role=photo-list-section]')).each(function() {
        $(this).on('jsend:success', function(event, data) {
          widget._updatePhotos(data);
        });
      });
    },

    fileupload: function(){
      var f = $('.fileupload', this.element);
      return f.fileupload.apply(f, arguments);
    }
  });

  $(document).ready(function() {
    updatePhotoUploader();
  });

})(jQuery);
