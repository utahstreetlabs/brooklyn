jQuery(function($) {
  function cancelOrder() {
    var $cancel = $('form', $("[data-role='reserved-time-content']"));
    $cancel.submit();
  }

  var $tickerBox = $("[data-role='reserved-time-ticker']");
  var $tickerExpires = $tickerBox.data('ticker-expiry');
  // ticker-expires is an expiration time in seconds; Date takes milliseconds
  $tickerBox.countdown({until: new Date($tickerExpires * 1000), compact: true,
                        format: 'MS', onExpiry: cancelOrder});
});
