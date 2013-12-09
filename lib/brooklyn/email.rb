module Brooklyn
  module Email
    extend ActiveSupport::Concern

    def format_email(*args)
      self.class.format_email(*args)
    end

    def from_email(*args)
      self.class.from_email(*args)
    end

    module ClassMethods
      def format_email(address, name)
        m = Mail::Address.new(address)
        m.display_name = name
        m.format
      end

      def from_email(options={})
        name = options[:name] || Brooklyn::Application.config.email.from.name
        address = options[:address] || Brooklyn::Application.config.email.from.noreply
        format_email(address, name)
      end
    end
  end
end
