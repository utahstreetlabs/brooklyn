# Validate a US ZIP code, allowing either five digits or nine digits with an optional '-' between
# thanks to Matt, commenter at http://bassistance.de/jquery-plugins/jquery-plugin-validation/
jQuery.validator.addMethod(
  "zipcodeUS",
  ((zip) -> zip = zip.replace(/^\s+|\s+$/g, ''); zip.length == 0 || zip.match(/^\d{5}([- ]?\d{4})?$/)),
  "Please specify a valid US ZIP code"
)
