module ProgressBarHelper
  def progress_bar(flow_steps, selected_step_key)
    output = []
    step_keys = flow_steps.keys
    selected_step = step_keys.index selected_step_key

    step_keys.each_index do |step|
      css_class = css_class_step(step, selected_step)
      key = step_keys[step]
      output << content_tag(:td, flow_steps[key], :class => css_class)
    end

    content_tag(:table, content_tag(:tr, output.join().html_safe), :class => ['progress-bar'])
  end

  def css_class_step(step, selected_step)
    return nil unless step && selected_step # separate rule for border case, no steps apply
    return "completed" if step < selected_step
    return "selected" if step == selected_step
    return nil if step > selected_step
  end
end
