#= require spec_helper
#= require search_browse/browse

describe 'layout.HorizontalBrowse', ->
  this.timeout(500)
  server = null

  $categoryTab = -> $('#category-container')
  $priceTab = -> $('#price-container')
  $sortTab = -> $('#sort-container')

  # Note: The URLs used are not correct and are just used for testing.
  #       The functions below also only handle server responses for the first option of each dropdown
  #       (except sort, which handles the response for the second option).
  responseTemplate = {
    categories: ['
      <li class="facet">
        <a href="/category/one" data-role="facet-change" data-title="Accessories">
          <span class="facet-name">Accessories</span><span class="facet-count"></span>
        </a>
      </li>
    ', '
      <li class="facet">
        <a href="/category/two" data-role="facet-change" data-title="Art">
          <span class="facet-name">Art</span><span class="facet-count"></span>
        </a>
      </li>
    '],
    tags: [],
    prices: ['
      <li class="facet">
        <a href="/price/one" data-role="facet-change" data-title="Under $25">
          <input data-role="facet-checkbox" data-url="/price/one" id="Under__25" name="Under $25"
           type="checkbox" value="0">
          <span class="facet-name">Under $25</span><span class="facet-count"></span>
        </a>
      </li>
    ', '
      <li class="facet">
        <a href="/price/one" data-role="facet-change" data-title="$25-$50">
          <input data-role="facet-checkbox" data-url="/price/two" id="_25-_50" name="$25-$50"
           type="checkbox" value="0">
          <span class="facet-name">$25-$50</span><span class="facet-count"></span>
        </a>
      </li>
    '],
    sizes: [],
    brands: [],
    conditions: [],
    sorts: ['
      <li class="selected">
        <a href="/sort/one" data-role="facet-change">Most Recent</a>
      </li>
    ', '
      <li>
        <a href="/sort/two" data-role="facet-change">Most Popular</a>
      </li>
    '],
    count: 42,
    cards: ['<div>Pretend these are cards</div>']
  }
  respondForCategory = ->
    server.respondWith(/\/category\/one/, data: { status: 'success', data: $.extend({}, responseTemplate, {
      title: 'Accessories',
      titles: {
        categories: 'Accessories',
        prices: 'All Prices',
        sorts: 'Most Recent'
      },
      selections: ['
        <span class="tag-interaction" data-role="facet-selection">
          Accessories
          <a href="/category/one" class="tag-remover" data-action="remove" data-role="facet-change" data-title="x">x</a>
        </span>
      ']
    })})

  respondForPrice= ->
    server.respondWith(/\/price\/one/, data: { status: 'success', data: $.extend({}, responseTemplate, {
      title: 'New Arrivals',
      titles: {
        categories: 'All Categories',
        prices: 'Under $25',
        sorts: 'Most Recent'
      },
      selections: ['
        <span class="tag-interaction" data-role="facet-selection">
          Under $25
        </span>
      ']
    })})

  respondForSort = ->
    server.respondWith(/\/sort\/two/, data: { status: 'success', data: $.extend({}, responseTemplate, {
      title: 'New Arrivals',
      titles: {
        categories: 'All Categories',
        prices: 'All Prices',
        sorts: 'Most Popular'
      },
      selections: []
    })})

  beforeEach ->
    $('body').html(JST['templates/layout/horizontal_browse']())
    server = new MockServer
    Copious.initBrowse()

  afterEach ->
    server.tearDown()

  # Test category filter
  describe 'clicking the category filter', ->
    beforeEach ->
      $categoryTab().find('.dropdown-toggle').click()

    it 'opens the dropdown', ->
      expect($categoryTab()).to.have.class('open')
      expect($categoryTab().find('.dropdown-menu')).to.be.visible

    describe 'and clicking it again', ->
      beforeEach ->
        $categoryTab().find('.dropdown-toggle').click()

      it 'closes the dropdown', ->
        expect($categoryTab()).to.not.have.class('open')
        expect($categoryTab().find('.dropdown-menu')).to.not.be.visible

    describe 'and clicking an option', ->
      beforeEach ->
        $categoryTab().find('[data-role=facet-change]:first').click()

      it 'does not close the dropdown', ->
        expect($categoryTab()).to.have.class('open')
        expect($categoryTab().find('.dropdown-menu')).to.be.visible

      it 'shows a loading image', ->
        expect($categoryTab().find('[data-role=facet-change]:first [data-role=spinner]')).to.exist

      describe 'with a server response', ->
        beforeEach ->
          respondForCategory()
          server.respond()

        it 'updates the search title', ->
          expect($('#title-container')).to.have.text('Accessories')

        it 'updates the results count', ->
          expect($('#items-found-number')).to.have.text('42')

        it 'updates the listing cards', ->
          expect($('.search-results')).to.have.text('Pretend these are cards')

        it 'updates the selections', ->
          expect($('#selection-container [data-role=facet-selection]')).to.exist

        it 'shows the selections', ->
          expect($('#selection-container')).to.be.visible

        it 'updates the filter title', ->
          expect($categoryTab().find('[data-role=dropdown-title]')).to.have.text('Accessories')

        it 'closes the dropdown', ->
          expect($categoryTab()).to.not.have.class('open')
          expect($categoryTab().find('.dropdown-menu')).to.not.be.visible

        it 'removes the loading image', ->
          expect($categoryTab().find('[data-role=facet-change]:first [data-role=spinner]')).to.not.exist

  # Test multi-select filters
  describe 'clicking the price filter', ->
    beforeEach ->
      $priceTab().find('.dropdown-toggle').click()

    it 'opens the dropdown', ->
      expect($priceTab()).to.have.class('open')
      expect($priceTab().find('.dropdown-menu')).to.be.visible

    describe 'and clicking it again', ->
      beforeEach ->
        $priceTab().find('.dropdown-toggle').click()

      it 'closes the dropdown', ->
        expect($priceTab()).to.not.have.class('open')
        expect($priceTab().find('.dropdown-menu')).to.not.be.visible

    describe 'and clicking an option', ->
      beforeEach ->
        $priceTab().find('[data-role=facet-change]:first').click()

      it 'does not close the dropdown', ->
        expect($priceTab()).to.have.class('open')
        expect($priceTab().find('.dropdown-menu')).to.be.visible

      it 'shows a loading image', ->
        expect($priceTab().find('[data-role=facet-change]:first [data-role=spinner]')).to.exist

      describe 'with a server response', ->
        beforeEach ->
          respondForPrice()
          server.respond()

        it 'updates the search title', ->
          expect($('#title-container')).to.have.text('New Arrivals')

        it 'updates the results count', ->
          expect($('#items-found-number')).to.have.text('42')

        it 'updates the listing cards', ->
          expect($('.search-results')).to.have.text('Pretend these are cards')

        it 'updates the selections', ->
          expect($('#selection-container [data-role=facet-selection]')).to.exist

        it 'shows the selections', ->
          expect($('#selection-container')).to.be.visible

        it 'updates the filter title', ->
          expect($priceTab().find('[data-role=dropdown-title]')).to.have.text('Under $25')

        it 'does not close the dropdown', ->
          expect($priceTab()).to.have.class('open')
          expect($priceTab().find('.dropdown-menu')).to.be.visible

        it 'removes the loading image', ->
          expect($priceTab().find('[data-role=facet-change]:first [data-role=spinner]')).to.not.exist

  # Test sort filter
  describe 'clicking the sort filter', ->
    beforeEach ->
      $sortTab().find('.dropdown-toggle').click()

    it 'opens the dropdown', ->
      expect($sortTab()).to.have.class('open')
      expect($sortTab().find('.dropdown-menu')).to.be.visible

    describe 'and clicking it again', ->
      beforeEach ->
        $sortTab().find('.dropdown-toggle').click()

      it 'closes the dropdown', ->
        expect($sortTab()).to.not.have.class('open')
        expect($sortTab().find('.dropdown-menu')).to.not.be.visible

    describe 'and clicking an option', ->
      beforeEach ->
        $sortTab().find('[data-role=facet-change]:eq(1)').click()

      it 'does not close the dropdown', ->
        expect($sortTab()).to.have.class('open')
        expect($sortTab().find('.dropdown-menu')).to.be.visible

      it 'shows a loading image', ->
        expect($sortTab().find('[data-role=facet-change]:eq(1) [data-role=spinner]')).to.exist

      describe 'with a server response', ->
        beforeEach ->
          respondForSort()
          server.respond()

        it 'updates the search title', ->
          expect($('#title-container')).to.have.text('New Arrivals')

        it 'updates the results count', ->
          expect($('#items-found-number')).to.have.text('42')

        it 'updates the listing cards', ->
          expect($('.search-results')).to.have.text('Pretend these are cards')

        it 'does not show the selections', ->
          expect($('#selection-container')).to.not.be.visible

        it 'updates the filter title', ->
          expect($sortTab().find('[data-role=dropdown-title]')).to.have.text('Most Popular')

        it 'closes the dropdown', ->
          expect($sortTab()).to.not.have.class('open')
          expect($sortTab().find('.dropdown-menu')).to.not.be.visible

        it 'removes the loading image', ->
          expect($sortTab().find('[data-role=facet-change]:first [data-role=spinner]')).to.not.exist
