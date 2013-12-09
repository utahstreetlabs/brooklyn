This directory contains [Vanity](https://github.com/assaf/vanity)
experiments.

To define a new experiment, find or create a new
[Metric](http://vanity.labnotes.org/metrics.html) and ensure it is
converted correctly within Brooklyn. This involves adding a call to
`track!` in the correct place[s], usually in a controller. Next,
define an [Experiment](http://vanity.labnotes.org/ab_testing.html) and
use the ab_test method in the right place, usually in a view.