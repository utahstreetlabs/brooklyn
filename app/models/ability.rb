require 'cancan/ability'

# Defines user permissions for authorization with CanCan. See https://github.com/ryanb/cancan/wiki/defining-abilities
# for more information.
#
# XXX: If we wind up needing more granular access control than the admin and superuser flags can give us, consider
# using role-based access control as discussed at https://github.com/ryanb/cancan/wiki/Role-Based-Authorization.
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user or visitor
    if user.superuser?
      # superuser can do anything
      can(:manage, :all)
      cannot(:destroy, User) { |u| Rails.env.production? }
    elsif user.admin?
      can(:manage, :all)
      cannot(:create, User)
      cannot(:destroy, User)
      cannot(:grant_superuser, User)
    end
  end
end
