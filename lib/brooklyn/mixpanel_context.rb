module Brooklyn
  module MixpanelContext
    extend ActiveSupport::Concern
    include Ladon::Context

    delegate :'mixpanel_context=', :mixpanel_context, to: 'self.class'

    module ClassMethods
      def mixpanel_context=(context)
        ladon_context[:mixpanel] = context
      end

      def mixpanel_context
        ladon_context[:mixpanel] || {}
      end
    end
  end
end
