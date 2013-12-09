module CollectionsHelpers
  def edit_collection(collection)
    find("[data-target='#{modal_id(collection)}']").click
  end

  def page_should_have_collection_edit_button
    page.should have_css('[data-action=edit-collection]')
  end

  def update_collection(collection, name)
    within_edit_collection_modal(collection) do
      fill_in 'collection_name', with: name
    end
    submit_edit_collection_form(collection)
    wait_a_sec_for_selenium
  end

  def update_should_succeed
    page.should have_content(I18n.t('controllers.collections.saved'))
  end

  def delete_collection(collection)
    within_edit_collection_modal(collection) do
      find('[data-action=delete-collection]').click
    end
    page.should_not have_edit_collection_modal
    page.should have_followup_delete_collection_modal
    within_followup_delete_collection_modal do
      find('[data-action=delete-collection]').click
    end
  end

  def delete_should_succeed(collection)
    page.should have_content(I18n.t('controllers.collections.deleted'))
  end

  def edit_should_not_be_allowed
    page.should have_content(I18n.t(:readonly, scope: 'activerecord.errors.models.collection.attributes'))
  end

  def submit_edit_collection_form(collection)
    within_edit_collection_modal(collection) do
      page.find('[data-save=modal]').click
    end
  end

  def dismiss_edit_success_collection_modal
    close_modal('edit-collection-success-modal')
  end

  def select_from_collection_selector(slug)
    within('[data-role=multi-collection-selector]') do
      page.find("[data-collection=#{slug}]").click
    end
  end

  def listing_page_create_new_collection(name)
    within('[data-role=multi-collection-selector]') do
      page.fill_in 'add_collection_input[]', with: name
      page.find('[data-action=add-collection]').click
    end
  end

  def modal_id(collection)
    "#edit-collection-#{collection.id}-modal"
  end

  def within_edit_collection_modal(collection, &block)
    within(modal_id(collection), &block)
  end

  def within_followup_delete_collection_modal(&block)
    within('[data-role=collection-edit-modal-delete]', visible: true, &block)
  end
end

RSpec.configure do |config|
  config.include CollectionsHelpers
end

RSpec::Matchers.define :have_edit_collection_modal do
  match do |page|
    page.has_css?('[data-role=collection-edit-modal]', visible: true)
  end
end

RSpec::Matchers.define :have_followup_delete_collection_modal do
  match do |page|
    page.has_css?('[data-role=collection-edit-modal-delete]', visible: true)
  end
end

