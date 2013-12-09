(function($) {
  function updateRememberMe() {
    var rm = {remember_me: $(this).attr('checked') ? 1 : 0};
    var facebookLink = $('[data-action=auth-facebook]');
    var twitterLink = $('[data-action=auth-twitter]');
    facebookLink.data('auth-url', $.url.extend(facebookLink.data('auth-url'), rm));
    twitterLink.attr('href', $.url.extend(twitterLink.attr('href'), rm));
  }

  $(document).ready(function(event) {
    var rm = $('#network-login-remember-me');
    rm.change(updateRememberMe);
    updateRememberMe.apply(rm);
  });
})(jQuery);
