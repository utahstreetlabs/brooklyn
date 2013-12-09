/**
 * A component presenting a rolling list of actions. Expects elements in the list to contain
 * Rails remote links and loads new elements from a url configured in the widget HTML.
 *
 * Options
 *
 * postActionFlicker - duration to wait after an action succesfully
 *   completes before rolling
 * actionSlideUpSpeed - speed with which we should slide the old
 *   action element up
 * seen - a list of identifiers of action element's we've "seen"
 *  can be used to avoid displaying the same action twice
 * seenParam - the query param name to use for seen identifiers
 *
 *
 * Data and Classes
 *
 * This widget relies on a number of classes and data attributes:
 *
 * classes:
 *   ra-act - remote links should carry this class
 *   ra-action - list elements should carry this class
 *   ra-list - the list element should carry this class
 *
 * data attributes:
 *   more: should live on the list element and should contain a url returning additional list elements
 *         in a jsend wrapper
 *
 * The "more" link should return a JSend response with data object of the form:
 *
 * {"results": [{"ui": "html of new list element"}]}
 *
 * The widget will append count=1 to the query strong of the "more" link. Multiple results will
 * be ignored.
 *
 *
 * Events
 *
 * The following events will be triggered on the widget element during the lifecycle of this widget:
 *
 * rollingActions:nextActionLoaded - triggered once the new list element is in place and the old
 *   list element has been removed
 *
 *
 * Requires jquery.timeout: http://plugins.jquery.com/project/jquery-timeout
 */
(function($){
  $.widget("copious.rollingActions", {
    options: {
      postActionFlicker: 1000,
      actionSlideUpSpeed: 400,
      seen: [],
      seenParam: 'blacklist'
    },

    _init: function(){
      this.options.list = $('.ra-list', this.element);
      this._rollAfterAction('a.ra-act');
      // don't flicker after removal - no need to provide feedback
      // this succeeded beyond just removing the action
      this._rollAfterAction('a.ra-remove', {postActionFlicker: 0});
    },

    /**
     *  before the action's remote link fires its HTTP request, kick
     *  off a request for the next suggestion and set up handlers
     */
    _rollAfterAction: function(remoteLinkSelector, options){
      var widget = this;
      $(remoteLinkSelector, this.element).live('ajax:beforeSend', function(event, actXHR) {
        widget._disableActLink(this);
        var moreDeferred = widget._fetchMore();
        moreDeferred.then(function(more) {
          var result = more.results[0];
          if (result) widget._addSeen(result.id);
        });
        var $action = $(this).closest('.ra-action');
        widget._waitForActionAndRoll($action, $.jsend.deferred(actXHR), moreDeferred, options);
      });
    },

    /**
     * Given a handle on a link, a deferred for an action request and a
     * deferred for a request for more actions, set up handlers to
     * update the UI.
     */
    _waitForActionAndRoll: function($action, waitForAction, haveNextAction, options){
      options = options || {};
      var widget = this;
      waitForAction.then(function(){
        // add a short pause to provide feedback that action has succeeded
        var flickerComplete = $.timeout(options.postActionFlicker || widget.options.postActionFlicker);
        $.when(haveNextAction, flickerComplete).then(function(more){
            widget._rollResultIn($action, more).then(function(){
              widget.element.trigger("rollingActions:nextActionLoaded");
            });
          });
      });
    },

    _rollResultIn: function(oldActionEl, moreResult){
      var result = moreResult.results[0];
      return this.roll(oldActionEl, result ? result.ui : null);
    },

    /**
     * Given two action elements, roll the old out and stick the new in.
     *
     * Return a deferred that will resolve when the roll is complete.
     */
    roll: function(oldActionEl, newActionEl){
      var options = this.options;
      return $.Deferred(function(dfd){
        if (newActionEl) options.list.append(newActionEl);
        $(oldActionEl).slideUp(options.actionSlideUpSpeed, dfd.resolve);
      // detach after sliding up - leave data and events around for
      // stuff like tooltips
      }).then(function (){$(oldActionEl).detach()});
    },

    _addSeen: function(id) {
      this.options.seen.push(id);
    },

    _disableActLink: function(link){
      $(link).click(function(){return false;});
    },

    _fetchMore: function(options){
      var options = options || {count: 2};
      options[this.options.seenParam] = this.options.seen;
      return $.jsend.get(this.options.list.data('more'), options);
    },

    refresh: function() {
      var widget = this;
      var actions = $('.ra-action', this.element);
      var moreDeferred = widget._fetchMore({count: actions.length});
      return moreDeferred.then(function(more) {
        for (var i = 0; i < actions.length; i++) {
          var result = more.results[i];
          if (result && result.ui) widget.roll(actions[i], result.ui);
        }
      });
    }
  });
})(jQuery);
