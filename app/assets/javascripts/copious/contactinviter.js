$.widget('copious.contactinviter', {
  options: {
    limit: 100,
    url: null,
    // backoff timing when polling for additional contacts to display
    pollSequence: [1000, 2000, 4000]
  },

  _showLoader: function() {
    this._resizeLoader();
    this._loader.show();
  },

  _hideLoader: function() {
    this._loader.hide();
  },

  _resizeLoader: function() {
    // ensure there's enough space to render the image
    var height = Math.max(this.element.outerHeight(false), 40),
        width = this.element.outerWidth(false);
    this._loader.height(height);
    this._loader.width(width);
  },

  _requestContacts: function() {
    var $inviter = this;
    $inviter._showLoader();
    var poller = $.poll(this.options.url, this.options.pollSequence, {
      dataType: 'json',
      success: function(data, textStatus, jqXHR) {
        $inviter._renderContacts(data.data);
        if (data.data.status === 'complete') {
          $inviter._hideLoader();
          return true;
        }
        return false;
      },
      error: function(jqXHR, textStatus, errorThrown) {
        $inviter._loader.hide();
        $inviter._renderError();
      }
    });
    $.subscribe(poller, 'poll:exhausted', function(event, data) {
      $inviter._renderError();
    });
  },

  _renderContacts: function(context) {
    var table = this._template(context);
    this.element.html(table);
    this._resizeLoader();
  },

  _renderError: function() {
    copious.flash.alert(
      "There was an error importing your contacts.  We will keep trying and let you know when we're done.");
  },

  _create: function() {
    this._template = $.compileTemplate('#contacts-template');
    this._loader = $($.compileTemplate('#loading-template')());
    this.element.before(this._loader);
    this._requestContacts();
  },

  selectedEmails: function() {
    return $('tr input:checkbox:checked', this.element).map(function(i, checkbox) {
      return $('.email-col', $(checkbox).closest('tr')).text();
    }).toArray();
  }
});
