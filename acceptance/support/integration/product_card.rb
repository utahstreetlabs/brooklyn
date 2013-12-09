module ProductCardIntegrationHelpers
  def like_product_card(listing)
    within_product_card(listing) do
      find('[data-action=love]').click
    end
  end

  def unlike_product_card(listing)
    within_product_card(listing) do
      find('[data-action=unlove]').click
    end
  end

  def product_card_should_be_liked(listing)
    within_product_card(listing) do
      page.should have_css('[data-action=unlove]')
    end
  end

  def product_card_should_not_be_liked(listing)
    within_product_card(listing) do
      page.should have_css('[data-action=love]')
    end
  end

  def comment_on_product_card(listing)
    within_product_card_back(listing) do
      fill_in "comment[text]", with: "ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn"
      send_enter_key('[data-role=product-card-comment-entry]')
    end
  end

  def product_card_front_should_not_be_commented(listing)
    within_product_card_front(listing) do
      page.should have_front_comments_count(0)
    end
  end

  def product_card_front_should_have_one_comment(listing)
    within_product_card_front(listing) do
      retry_expectations do
        page.should have_front_comments_count(1)
      end
    end
  end

  def product_card_back_should_not_be_commented(listing)
    within_product_card_back(listing) do
      page.find('[data-role=product-card-comment-header]').text.should
        have_content(I18n.t('product_card.v4.comment_listing_first'))
    end
  end

  def product_card_back_should_have_one_comment(listing)
    within_product_card_back(listing) do
      retry_expectations do
        page.should have_back_comments_count(1)
      end
    end
  end

  def flip_product_card_to_comments(listing)
    within_product_card_front(listing) do
      find('[data-action=comment]').click
    end
    wait_for_dom_to_update
    retry_expectations do
      page.has_css?('[data-action=close-comment-card]', visible: true).should be_true
    end
  end

  def flip_product_card_from_comments(listing)
    within_product_card_back(listing) do
      find('[data-action=close-comment-card]').click
    end
    wait_for_dom_to_update
    retry_expectations do
      page.has_css?('[data-action=comment]', visible: true).should be_true
    end
  end

  def within_product_card(listing, &block)
    within "#product-card-#{listing.id}", &block
  end

  def within_product_card_front(listing, &block)
    within_product_card(listing) do
      within "[data-card-side=front]", &block
    end
  end

  def within_product_card_back(listing, &block)
    within_product_card(listing) do
      within "[data-card-side=back]", &block
    end
  end
end

RSpec.configure do |config|
  config.include ProductCardIntegrationHelpers
end

RSpec::Matchers.define :have_front_comments_count do |count|
  match do |page|
    page.find('[data-role=comments-count]').text.strip.to_i.should == count
  end
end

# For comment values > 0; if a card has no comments, there is no header.
RSpec::Matchers.define :have_back_comments_count do |count|
  match do |page|
    page.find('[data-role=product-card-comment-header]').text.should =~ /#{count} comment/
  end
end
