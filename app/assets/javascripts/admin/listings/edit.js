(function($) {
  $(document).ready(function() {
    $('#listing_description').wysiwyg({
      initialContent: '',
      css: '/assets/application.css',
      rmUnusedControls: true,
      controls: {
        bold: { visible : true, groupIndex: 1 },
        italic: { visible : true, groupIndex: 1 },
        underline: { visible : true, groupIndex: 1 },
        insertOrderedList: { visible : true, groupIndex: 2 },
        insertUnorderedList: { visible : true, groupIndex: 2 },
        insertHorizontalRule: { visible : true, groupIndex: 2 },
        undo: { visible : true, groupIndex: 3 },
        redo: { visible : true, groupIndex: 3 }
      },
      autoGrow: true,
      maxHeight: 300,
      events: {
        afterInit: function(event) {
          $(event.target).find('body').attr('id', 'product-description');
        }
      }
    });

    $('#listing_tags').tagsInput({
      autocomplete_url: '<%= Brooklyn::Application.routes.url_helpers.typeahead_tags_path %>', 'unique': false
    });
  });
})(jQuery);
