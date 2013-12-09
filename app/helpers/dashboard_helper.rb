module Dashboard
  # Base class for exhibits for the "status / next step" area on dashboard order pages. The page contains one of these
  # areas for each displayed listing. A next step area may contain one or more next step controls.
  #
  # Modals
  # ------
  #
  # For now, there is no explicit exhibit class or helper class for a modal control. Exhibits that use modal controls
  # follow this general pattern:
  #
  #   def render
  #     button + modal_container { modal }
  #   end
  #
  #   def button
  #     context.bootstrap_button('Do something', '#', toggle_modal: modal_id)
  #   end
  #
  #   def modal
  #     context.bootstrap_modal(modal_id, 'Do something') do
  #       modal_content_container do
  #         # modal content
  #       end
  #     end
  #   end
  #
  #   def modal_id
  #     "do-something-#{self.id}"
  #   end
  #
  # Other control types
  # -------------------
  #
  # +#order_next_steps# supports a number of other control types which should migrated here over time:
  #
  # 1. Button that links to external resource
  # 2. Partial
  # 3. Custom helper method
  # 4. Static text
  # 5. Composite (multiple buttons, button + text, etc)
  #
  # As more of these controls are supported, it will probably make sense to implement them using helper classes
  # rather than as methods on this class, especially since other exhibits will probably want to use those helpers
  # too.
  class OrderNextStepExhibit < Exhibitionist::Exhibit
    # The container in which a +bootstrap_modal+ is enclosed.
    def modal_container(&block)
      context.content_tag(:div, data: {role: 'dashboard-order-modal', order: self.id}, &block)
    end

    # The container in which the content of a +bootstrap_modal+ should be enclosed.
    def modal_content_container(&block)
      context.content_tag(:div, id: modal_id, data: {order: self.id}, &block)
    end

    # Returns a translated string in the scope defined by +#i18n_scope+ (unless overridden by +params+).
    def t(key, params = {})
      params = params.dup
      params.reverse_merge!(scope: self.class.i18n_scope)
      context.t(key, params)
    end

    # Subclasses can override this to more explicitly scope their translated strings.
    def self.i18n_scope
      'exhibits.dashboard'
    end
  end
end

module DashboardHelper
  def dash_order_status(order)
    status, substatus = order_status(order)
    out = []
    out << status if status.present?
    out << content_tag(:span, substatus) if substatus.present?
    out.join(' ').html_safe
  end

  def dash_buyer_privacy_container(order)
    content_tag(:div, data: {order: order.id, role: :'buyer-privacy'}) do
      content_tag(:span) do
        dash_order_privacy_control(order) + order_privacy_hint
      end
    end
  end

  def dash_order_privacy_control(order)
    bootstrap_button_group(class: 'buttons privacy-toggle', toggle: :radio, data: {role: :'buyer-privacy'}) do
      bootstrap_button(t('dashboard.bought.public'), dashboard_order_public_path(order), active: order.public?,
        class: 'button small', remote: true, method: :post, data: {link: :'multi-remote', action: :public}) +
      bootstrap_button(t('dashboard.bought.private'), dashboard_order_private_path(order), active: order.private?,
        class: 'button small', remote: true, method: :post, data: {link: :'multi-remote', action: :private})
    end
  end

  def seller_listing_next_steps(listing)
    steps = case listing.state.to_sym
    when :incomplete
      [{text: 'Complete', action: :setup, button_style: :small},
       {text: 'Cancel', action: :destroy, method: :DELETE, button_style: [:soft, :small], confirm: 'Are you sure?'}]
    when :inactive
      [{text: 'Publish', action: :activate, method: :POST, button_style: [:primary, :small]},
       {text: 'Edit', action: :edit, button_style: :small},
       {text: 'Cancel', action: :destroy, method: :DELETE, button_style: [:soft, :small], confirm: 'Are you sure?'}]
    when :suspended
       [{text: 'Edit', action: :edit, button_style: :small},
        {text: 'Cancel', action: :destroy, method: :DELETE, button_style: [:soft, :small], confirm: 'Are you sure?'}]
    when :active
      [{text: 'Edit', action: :edit, button_style: :small},
       {text: 'Cancel', action: :destroy, method: :DELETE, button_style: [:soft, :small], confirm: 'Are you sure?'}]
    else
      raise "Unsupported listing state #{listing.state}"
    end
    listing_next_step_buttons(listing, steps)
  end

  def listing_next_step_buttons(listing, steps)
    out = steps.map do |step|
      if step.include?(:action)
        url_options = {controller: :listings, action: step[:action], id: listing.slug}
        button_style = step.fetch(:button_style, :positive)
        button_class = button_style.is_a?(Array) ? button_style.join(' ') : button_style
        options = {class: "button #{button_class}", confirm: step[:confirm]}
        if step[:method]
          options[:method] = step[:method]
          options[:rel] = :nofollow
        end
        link_to(step[:text], url_options, options)
      end
    end
    out.flatten.join("\n").html_safe
  end

  def buyer_order_next_steps(order)
    viewer = current_user
    steps = case order.status.to_sym
    when :confirmed then [{text: 'Sit tight'}]
    when :shipped
      if order.delivery_confirmation_elapsed?
        [{exhibit: Dashboard::Buyer::DeliveryConfirmationElapsedExhibit.new(order, viewer, self)}]
      else
        [{:text => 'Track', :helper => :tracking_form}]
      end
    when :delivered then [{:text => 'Complete', :form => :complete}]
      #, {:text => 'Report issue'}]
#    when :return_pending then [{:text => 'Enter tracking #'}]
#    when :return_shipped then [{:text => 'Track'}]
#    when :return_delivered then [{:text => 'Track'}]
    else []
    end
    if feature_enabled?(:feedback)
      steps << {helper: :dash_buyer_privacy_container}
    end
    order_next_step_buttons(order, steps)
  end

  def seller_order_next_steps(order)
    viewer = current_user
    steps = case order.status.to_sym
    when :confirmed then
      if order.listing.prepaid_shipping? && !order.expired_shipping_label?
        [{:text => 'Simple Ship', :action => :simple_ship, button_style: :small}]
      else
        [{exhibit: Dashboard::Seller::ConfirmedBasicShippingExhibit.new(order, viewer, self)}]
      end
    when :shipped then [{:text => 'Track', :helper => :tracking_form, button_style: :small}]
#    when :return_pending then [{:text => 'Review', :action => 'return_review'}]
#    when :return_shipped then [{:text => 'Track', :action => 'return_track'}]
#    when :return_delivered then [{:text => 'Confirm', :action => 'return_confirm'}]
    else []
    end
    order_next_step_buttons(order, steps)
  end

  def order_next_step_buttons(order, steps)
    out = steps.map do |step|
      if step.include?(:exhibit)
        step[:exhibit].render
      elsif step.include?(:action)
        if step[:action] == :simple_ship
          link_to_manage_prepaid_shipping(order.listing, :class => 'button ')
        else
          link_to(step[:text], '#', :class => 'button ',
            :rel => "##{step[:action]}-order-#{order.id}")
        end
      elsif step.include?(:form)
        capture { render "/orders/#{step[:form]}_form", :order => order, :source => :dashboard }
      elsif step.include?(:helper)
        send(step[:helper], order)
      elsif step.include?(:text)
        content_tag(:span, step[:text])
      end
    end
    out.flatten.join("\n").html_safe
  end

  def link_to_manage_prepaid_shipping(listing, options = {})
    link_to 'Simple Ship', listing_path(listing), options
  end
end
