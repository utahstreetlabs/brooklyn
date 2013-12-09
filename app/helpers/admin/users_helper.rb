module Admin::UsersHelper
  def suggested_user_strip(user)
    content_tag(:div, :class => 'row', data: {role: 'user-strip', user: user.id}) do
      suggested_user_strip_user_name(user) +
      content_tag(:div, :class => 'pull-left span9') do
        user_avatar_medium(user, :class => 'text-adjacent')
      end
    end
  end

  def suggested_user_strip_user_name(user)
    content_tag(:div, :class => 'pull-left span9') do
      link_to_user_profile(user, target: "_new") do
        content_tag(:h4, user.name)
      end
    end
  end

  def admin_user_interest_suggestions(user)
    out = user.suggested_for_interests.by_name.inject([]) do |m, interest|
      m << link_to(admin_interest_path(interest)) do
        content_tag(:span, interest.name, data: {interest: interest.id})
      end
    end
    safe_join(out, ', ')
  end
end
