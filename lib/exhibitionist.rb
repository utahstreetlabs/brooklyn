require 'exhibitionist/renderer/custom'
require 'exhibitionist/renderer/helper'
require 'exhibitionist/renderer/i18n_string'
require 'exhibitionist/renderer/partial'
require 'exhibitionist/exhibit'

# Implements the Exhibit pattern for rendering views of objects as described by Mike Pack at
# http://mikepackdev.com/blog_posts/31-exhibit-vs-presenter based on Avidi Grimm's book at http://objectsonrails.com/.
#
# "The primary goal of exhibits is to connect a model object with a context for which it's rendered." In terms of a
# Rails application, the context is a view context, generally an instance of ActionView::Base; in other words, a
# specific view template with helper methods mixed into it. The exhibit's job is to provide enough auxiliary
# information about the model object that some representation of the object can be included into the string of HTML
# or JSON or whatever that is rendered by the view. The exhibit exists in order to not pollute the model with
# presentational concerns and to distinguish the concerns of one individual view context from any others.
#
# "Exhibits shouldn't know about the language of the view (eg HTML)." This is a bit of a purist view, but we can get
# pretty close to it without compromising pragmatism. We use renderers to encapsulate various mechanisms for rendering
# the view of the object. Renderers included with Exhibitionist include one that renders an translated string via the
# I18n library, one that renders a Rails partial and one that invokes a Rails view helper.
