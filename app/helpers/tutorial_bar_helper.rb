module TutorialBarHelper
  def tutorial_bar(presenter, options = {})
    mp_view_event('tutorial_bar', share_channel: 'facebook_request')
    content_tag(:div, class: 'affix-container tutorial', data: {role: 'tutorial-bar', source: 'tutorial_bar'}) do
      content_tag(:div, data: {spy: 'affix', 'offset-top' => 336}, class: 'sticky-strip') do
        content_tag(:div, class: 'sticky-strip-content') do
          out = []
          out << content_tag(:div, class: 'sticky-strip-header-container') do
            out2 = []
            out2 << content_tag(:h1, t(:title, scope: :tutorial_bar), class: 'strip-header')
            out2 << content_tag(:p, t(:description_html, scope: :tutorial_bar), class: 'strip-text')
            safe_join(out2)
          end
          out << content_tag(:ul, class: 'tutorial-steps') do
            steps = presenter.steps.each_with_index.map do |step, i|
              send(step.renderer, step, i + 1)
            end
            safe_join(steps)
          end
          safe_join(out)
        end
      end
    end
  end

  def tutorial_step(step, number, &content)
    classes = []
    classes << 'complete' if step.complete?
    classes << 'suggestion' if step.suggested?
    content_tag(:li, class: class_attribute(classes), data: {role: 'tutorial-step', 'tutorial-action' => step.action}) do
      out = []
      out << content.call
      out << content_tag(:div, class: 'tutorial-header') do
        content_tag(:span, number, class: 'steps') + t(:cta, scope: step.i18n_scope)
      end
      safe_join(out)
    end
  end

  def tutorial_example(clazz, options = {}, &example_content)
    content_tag(:div, class: clazz) do
      out = []
      out << content_tag(:div, '', class: 'tutorial-example', &example_content)
      out << content_tag(:div, '', class: 'circle-highlight') if options[:highlighted]
      safe_join(out)
    end
  end

  def tutorial_like_step(step, step_number)
    tutorial_step(step, step_number) do
      tutorial_example('tutorial-example-love', highlighted: true)
    end
  end

  def tutorial_comment_step(step, step_number)
    tutorial_step(step, step_number) do
      tutorial_example('tutorial-example-comment', highlighted: true)
    end
  end

  def tutorial_invite_step(step, step_number)
    tutorial_step(step, step_number) do
      tutorial_example('tutorial-example-invite', highlighted: false) do
        invite_modal_invite_button(t('tutorial_bar.tutorial_invite_step.invite_button'), class: 'tutorial-invite button primary')
      end
    end
  end
end
