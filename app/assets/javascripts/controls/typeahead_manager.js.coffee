# Array-backed, binary-searched local cache store for typeahead manager
class ArrayTypeaheadStore
  constructor: (@lookupFn, @compareFn) ->
    @index = []

  _prefixCompare: (object, prefix) =>
    key = this.lookupFn(object)
    return 0 if (key.indexOf(prefix) is 0)
    return -1 if key < prefix
    1

  _reverseScanFirst: (start, prefix, compare) =>
    first = start
    for i in [start..0]
      if compare(@index[i], prefix) isnt 0
        first = i + 1
        break
    first

  # the recursive portion of the `_first` function
  _rFirst: (object, compare, min, max) =>
    return max if max == min
    pos = min + Math.round((max - min) / 2)
    if pos == max
      # min and max are adjacent, max might be out of bounds
      return if compare(@index[min], object) < 0 then max else min
    if compare(@index[pos], object) < 0
      this._rFirst(object, compare, pos, max)
    else
      this._rFirst(object, compare, min, pos)

  # return the position of the first value in the array that is considered a match with the provided `compare`
  # function.  if no match is found, the index of the first "larger" object is returned (because that makes splicing
  # easy and this is a private function)
  _first: (object, compare) =>
    this._rFirst(object, compare, 0, @index.length)

  insert: (object) ->
    first = this._first(object, this.compareFn)
    @index.splice(first, 0, object) unless (@index[first] and this.compareFn(@index[first], object) is 0)

  processSuggestions: (prefix, fn) ->
    suggestions = []
    prefix = prefix.toLowerCase()
    first = this._first(prefix, this._prefixCompare)
    first = this._reverseScanFirst(first, prefix, this._prefixCompare)
    _.every([first...@index.length], (i) =>
      obj = @index[i]
      if obj and this._prefixCompare(obj, prefix) is 0
        suggestions.push(obj)
        true
      else
        false
    )
    fn(suggestions)


# Trie(ish)-backed local cache store for typeahead manager
class TrieTypeaheadStore
  constructor: (@lookupFn, @compareFn) ->
    @index = {}

  insert: (object) ->
    key = this.lookupFn(object)
    node = @index
    # descend to the appropriate point in the tree
    _.each(key.split(''), (char) ->
      c = char.toLowerCase()
      node[c] ?= {}
      node = node[c]
    )
    node.values ?= []
    insertIndex = -1
    duplicate = false
    # use `every` here in place of `each` because it provides the same side-effects but also allows us to shortcut
    # iteration by returning false
    _.every(node.values, (value, index) =>
      switch this.compareFn(object, value)
        when -1
          insertIndex = index
          return false
        when 0
          duplicate = true
          return false
      return true
    )
    return if duplicate
    if insertIndex > -1
      node.values.splice(insertIndex, 0, object)
    else
      node.values.push(object)

  _eachSuggestion: (node, fn) ->
    (fn(s) for s in node.values) if node.values
    this._eachSuggestion(node[k], fn) for k in ((k for k,n of node when k.length is 1).sort())

  processSuggestions: (prefix, fn) ->
    node = @index
    _.every(prefix.split(''), (char) ->
      c = char.toLowerCase()
      node = node[c]
      node?
    )
    suggestions = []
    this._eachSuggestion(node, (s) -> suggestions.push(s)) if node
    fn(suggestions)


class TypeaheadManager
  # @lookupFn gets a key for prefix indexing out of an object
  # @compareFn compares two objects for sorting
  # @createFn takes a name and returns a new object, by default returning `null` to signify no creation allowed
  constructor: (@lookupFn, @compareFn, @sourceUrl, @resultMapFn, @createFn = (n) -> null) ->
    @store = new ArrayTypeaheadStore(@lookupFn, @compareFn)
    @queries = {}

  insert: (object) -> @store.insert(object)

  insertMany: (objects) -> (this.insert(o) for o in objects)

  processSuggestions: (prefix, fn) ->
    return if prefix.length is 0
    if @sourceUrl and this.resultMapFn and not @queries[prefix]
      $.jsend.get(@sourceUrl, query: prefix).then((data) =>
        @queries[prefix] = true
        this.insertMany(this.resultMapFn(o) for o in data.options)
        @store.processSuggestions(prefix, fn)
      )
    else
      @store.processSuggestions(prefix, fn)


window.Copious ?= {}
window.Copious.TypeaheadManager = TypeaheadManager
