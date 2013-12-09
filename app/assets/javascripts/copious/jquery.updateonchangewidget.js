(function($) {
  $.widget("copious.updateOnChange", {
    options: {
      url : '',
      afterUpdate: function(){}, //additional function that gets called after html is updated, passed returned json obj
      updateElement: '', //jquery selector
      jsonKey: 'html',  //the key for the html within the returned json object
      event: 'change'    //why not!
    },

    _init: function() {
      if ( this.options.url == '' || this.options.updateElement == '' ) {
        throw("updateOnChange requires options: { url: '/resource/1', updateElement: '#content' }")
      }

      var widget = this;
      this.element.bind( widget.options.event ,function(){
        $(widget.options.updateElement).html('<img src="/assets/icons/ajax-loader.gif" />');
        $.ajax({
          url: widget.options.url,
          dataType: 'json',
          data: $(this).parents('form:first').serialize(),
          success: function(json){
           $(widget.options.updateElement).html( json.data[widget.options.jsonKey]);
            widget.options.afterUpdate(json);
          }
        });
      })
    }

  })
})(jQuery);
