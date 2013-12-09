class Settings::PrivacyController < ApplicationController
  layout 'settings'
  set_flash_scope 'settings.privacy'

  before_filter { respond_not_found unless feature_enabled?(:feedback) }

  def show
    @privacy = Privacy.create_with_defaults(current_user.privacy_prefs)
  end

  def update
    @privacy = Privacy.new(params[:privacy])
    if @privacy.valid?
      if current_user.save_privacy_prefs(@privacy.to_prefs)
        set_flash_message(:notice, :updated)
        return redirect_to(settings_privacy_path)
      else
        set_flash_message(:alert, :error_updating)
      end
    end
    render :show
  end

  class Privacy
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    PREFS = [:purchase_details]

    PREFS.each do |key|
      attr_accessor key
      validates key, presence: true, inclusion: {:in => %w[true false], allow_blank: true}
    end

    def initialize(attrs = {})
      attrs.each do |name, value|
        send("#{name}=", value)
      end
    end

    def to_prefs
      PREFS.each_with_object({}) { |key, m| m[key] = send(key) == 'true' }
    end

    def persisted?
      false
    end

    # Returns the current user's privacy prefs, defaulting to public for all prefs without stored values.
    #
    # When we fail to get prefs from the server, instead default all prefs to private.
    def self.create_with_defaults(prefs)
      default = prefs ? false : true
      prefs = PREFS.each_with_object({}) { |key, m| m[key] = prefs ? prefs.fetch(key, default) : default }
      Privacy.new(prefs)
    end
  end
end
