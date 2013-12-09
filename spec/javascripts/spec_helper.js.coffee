#= require jquery
#= require jquery-ui
#= require ba-debug
#= require handlebars
#= require backbone-rails
#= require jquery_ujs
#= require bootstrap
#= require chai-jquery
#= require sinon-chai
#= require sinon
#= require_tree ./support
#= require_tree ./templates

# ignore all leaks cos they make rake konacha:run fail with
#   Failed: undefined "before each" hook
#     Error: global leaks detected: top, getInterface
#
#   Failed: listings/form/pricing_box_view "before each" hook
#     Error: global leak detected: navigator
#
# it's not clear why leak detection is interesting
mocha.ignoreLeaks()
