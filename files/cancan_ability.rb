class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    user ||= User.new # guest user

        if user.role == "admin" # || user.role == "dj"
               can :manage, :all
        else
          can [:read, :edit, :update], User do |u|
            u.try(:id) == user.id #This ensures that a user with role not "admin" can only edit their own profile
          end
          
        end

  end
end
