#= require controls/admin/user_typeahead

jQuery ->
  $('#message_query').adminUserTypeahead(slugInput: $('#message_slug'))
