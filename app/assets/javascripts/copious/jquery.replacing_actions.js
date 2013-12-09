/**
 * A component presenting a list of actions; new additions replace old elements inline. 
 * Expects elements in the list to contain Rails remote links and loads new elements from a url 
 * configured in the widget HTML.
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
 * position - position in the list of an element being replaced
 * positionParam - the query param name to use for position
 *
 *
 * Data and Classes
 *
 * This widget relies on a number of classes and data attributes:
 *
 * classes:
 *   rep-act - remote links should carry this class
 *   rep-action - list elements should carry this class
 *   rep-list - the list element should carry this class
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
 * replacingActions:nextActionLoaded - triggered once the new list element is in place and the old
 *   list element has been removed
 *
 *
 * Requires jquery.timeout: http://plugins.jquery.com/project/jquery-timeout
 */
(function($){
  $.widget("copious.replacingActions", {
    options: {
      postActionFlicker: 1000,
      actionSlideUpSpeed: 400,
      seen: [],
      seenParam: 'blacklist',
      positionParam: 'index',
      position: 0
    },

    _init: function(){
      this.options.list = $('.rep-list', this.element);
      this._replaceAfterAction('a.rep-act');
      // don't flicker after removal - no need to provide feedback
      // this succeeded beyond just removing the action
      this._replaceAfterAction('a.rep-remove', {postActionFlicker: 0});
    },

    /**
     *  before the action's remote link fires its HTTP request, kick
     *  off a request for the next suggestion and set up handlers
     */
    _replaceAfterAction: function(remoteLinkSelector, options){
      var widget = this;
      $(remoteLinkSelector, this.element).live('ajax:beforeSend', function(event, actXHR) {
        widget._disableActLink(this);
        widget._addPosition(this);
        var moreDeferred = widget._fetchMore();
        moreDeferred.then(function(more) {
          var result = more.results[0];
          if (result) widget._addSeen(result.id);
        });
        widget._waitForActionAndReplace(this, $.jsend.deferred(actXHR), moreDeferred, options);
      });
    },

    /**
     * Given a handle on a link, a deferred for an action request and a
     * deferred for a request for more actions, set up handlers to
     * update the UI.
     */
    _waitForActionAndReplace: function(actLink, waitForAction, haveNextAction, options){
      options = options || {};
      var widget = this;
      waitForAction.then(function(){
        // add a short pause to provide feedback that action has succeeded
        var flickerComplete = $.timeout(options.postActionFlicker || widget.options.postActionFlicker);
        $.when(haveNextAction, flickerComplete).then(function(more){
            var $action = $(actLink).closest('.rep-action');
            widget._replaceResult($action, more).then(function(){
              widget.element.trigger("replacingActions:nextActionLoaded");
            });
          });
      });
    },

    _replaceResult: function(oldActionEl, moreResult){
      var result = moreResult.results[0];
      return this.replace(oldActionEl, result ? result.ui : null);
    },

    /**
     * Given two action elements, replace the old with the new
     *
     * Return a deferred that will resolve when the replace is complete.
     */
    replace: function(oldActionEl, newActionEl){
      var options = this.options;
      return $.Deferred(function(dfd){
        if (newActionEl) options.list.find(oldActionEl).replaceWith($(newActionEl));
        $(oldActionEl).slideUp(options.actionSlideUpSpeed, dfd.resolve);
      }).then(function (){$(oldActionEl).remove()});
    },

    _addSeen: function(id) {
      this.options.seen.push(id);
    },

    _addPosition: function(link) {
      this.options.position = $(link).parent().index('.rep-action')
    },

    _disableActLink: function(link){
      $(link).click(function(){return false;});
    },

    _fetchMore: function(options){
      var options = options || {count: 2};
      options[this.options.seenParam] = this.options.seen;
      options[this.options.positionParam] = this.options.position;
      return $.jsend.get(this.options.list.data('more'), options);
    },

    refresh: function() {
      var widget = this;
      var actions = $('.rep-action', this.element);
      var moreDeferred = widget._fetchMore({count: actions.length});
      return moreDeferred.then(function(more) {
        for (var i = 0; i < actions.length; i++) {
          var result = more.results[i];
          if (result && result.ui) widget.replace(actions[i], result.ui);
        }
      });
    }
  });
})(jQuery);
