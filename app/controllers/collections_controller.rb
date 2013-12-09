class CollectionsController < ApplicationController
  include Controllers::Jsendable
  include Controllers::CollectionScoped

  load_collection except: :create

  before_filter :require_owner, except: :create
  before_filter :require_editable, except: :create

  def create
    collection = current_user.collections.build(name: params[:collection][:name])
    collection.save or
      return respond_with_jsend(fail: {
        modal: collections_exhibit(collection),
        errors: collection.errors
      })
    data = {
      name: collection.name,
      id: collection.slug,
      # This is used to update any dropdown menu that might be on the page with the new collection.
      dropdownMenu: collections_dropdown_menu_exhibit(current_user.collections)
    }
    # By default, the context for the collection is within the create collection modal.
    # However, it's also possible for us to create a collection in other contexts, such as
    # within a dropdown list of collections.  Used to determine how to refresh the page.
    case (params[:collection][:context] || :modal).to_sym
    when :modal
      # modal resets the create modal back to its original state, thus it takes a brand new collection
      # followup modal presents listings to add to the newly-created collection
      data[:modal] = collections_exhibit(Collection.new)
      data[:followupModal] = listings_modal_exhibit(collection)
    when :standalone
      data[:list_item] = view_context.collection_dropdown_item(collection)
      data[:selectable] = view_context.save_listing_to_collection_selectable(collection, selected: true)
    end
    respond_with_jsend(success: data)
  end

  def populate
    @collection.add_listings(params[:listing_id])
    respond_with_jsend(success: {
      followupModal: success_modal_exhibit(@collection)
    })
  end

  def update
    @collection.name = params[:collection][:name]
    if @collection.save
      respond_with_jsend(success: {
        alert: view_context.bootstrap_flash(:notice, localized_flash_message(:saved)),
        refresh: collection_card_exhibit(@collection),
        followupModal: view_context.edit_collection_success_modal(@collection)
      })
    else
      # Restore the old name so the refresh modal contains proper data.
      @collection.name = @collection.name_was
      respond_with_jsend(fail: {
        modal: collections_exhibit(@collection),
        errors: @collection.errors
      })
    end
  end

  def destroy
    @collection.destroy
    respond_with_jsend(success: {
      alert: view_context.bootstrap_flash(:notice, localized_flash_message(:deleted)),
      refresh: collection_cards_exhibit(current_user)
    })
  end

  protected
    def collections_exhibit(collection)
      CollectionsExhibit.new(collection, current_user, view_context).render
    end

    def collection_cards_exhibit(profile_user)
      CollectionCardsExhibit.new(profile_user, current_user, view_context).render
    end

    def collection_card_exhibit(collection)
      CollectionCardExhibit.new(collection, current_user, view_context).render
    end

    def listings_modal_exhibit(collection)
      Collections::Create::ListingsExhibit.new(collection, current_user, view_context).render
    end

    def success_modal_exhibit(collection)
      Collections::Create::SuccessExhibit.new(collection, current_user, view_context).render
    end

    def collections_list_item_exhibit(collection)
      Collections::ListItemExhibit.new(collection, current_user, view_context).render
    end

    def collections_dropdown_menu_exhibit(collections)
      Collections::DropdownMenuExhibit.new(collections, current_user, view_context).render
    end

    def require_owner
      unless @collection.owned_by?(current_user)
        respond_with_jsend(fail: {
          message: I18n.t('collection_card.not_owner')
        })
      end
    end

    def require_editable
      unless @collection.editable?
        @collection.errors.add(:base, I18n.t(:readonly, scope: 'activerecord.errors.models.collection.attributes'))
        respond_with_jsend(fail: {
          errors: @collection.errors
        })
      end
    end
end
