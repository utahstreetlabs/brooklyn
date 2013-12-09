module ActiveModel
  # Add "warnings" to a class. warnings function like Active Model errors but
  # have no effect on validation.
  #
  # Thanks to https://github.com/mattdenner/activerecord-warnings for prior art
  module Warnings
    extend ActiveSupport::Concern

    def warnings
      @warnings ||= ActiveModel::Errors.new(self)
    end
  end
end
