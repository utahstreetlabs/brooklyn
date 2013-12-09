require 'brooklyn/i18n'

# Extend I18n::Backend::Simple to support a/b testing localization strings.
# The backend is designed to be extended like this - see
# https://github.com/svenfuchs/i18n/blob/master/lib/i18n/backend/simple.rb#L3
module I18nABTesting
  include Brooklyn::I18n

  def lookup(*args)
    ab_test_copy(super)
  end
end

I18n::Backend::Simple.include(I18nABTesting)
