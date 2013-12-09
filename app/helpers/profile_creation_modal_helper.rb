module ProfileCreationModalHelper
  def profile_creation_modal
    bootstrap_modal('new-profile', t('new_profile.modal.title'), never_close: true,
                    show_close: false, save_button_text: t('new_profile.modal.save.label')) do

    end
  end
end
