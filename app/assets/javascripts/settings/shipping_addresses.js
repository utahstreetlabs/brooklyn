jQuery(function($) {
  var $editAddress = $('.edit-address');
  var $newAddress = $('#new-address');
  var $showNewAddress = $('#show-new-address');

  $editAddress.each(function() {
    var $edit = $('.edit', this);
    var $address = $('.address', this);
    var $fields = $('.fields', this);
    var $cancel = $('.cancel', this);

    $edit.click(function() {
      $address.hide();
      $showNewAddress.hide();
      $fields.show();
      return false;
    });

    $cancel.click(function() {
      $address.show();
      $showNewAddress.show();
      $fields.hide();
      return false;
    });
  });

  $showNewAddress.click(function() {
    $editAddress.hide();
    $showNewAddress.hide();
    $newAddress.show();
    return false;
  });

  $newAddress.each(function() {
    var $cancel = $('.cancel', this);

    $cancel.click(function() {
      $newAddress.hide();
      $editAddress.show();
      $showNewAddress.show();
      return false;
    });
  });
});
