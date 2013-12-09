//= require jquery/wysiwyg/jquery.wysiwyg
//= require jquery/wysiwyg/wysiwyg.link

jQuery(function($) {
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
    initialMinHeight: 150,
    resizeOptions: true,
    events: {
      afterInit: function(event) {
        $(event.target).find('body').attr('id','product-description');
      }
    }
  });

  function resetHeight(){
    $('#listing_description-wysiwyg-iframe').contents().find('head').append('<style>head, body{height:initial}</style>')
  }

  setTimeout(resetHeight, 500);


});
