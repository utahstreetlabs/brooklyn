module Admin
  module InterestsHelper
    def admin_interest_gender(gender)
      case gender
      when true then 'Male'
      when false then 'Female'
      else 'All'
      end
    end
  end
end
