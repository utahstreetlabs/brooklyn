class TutorialBar
  include Ladon::Logging

  attr_reader :steps, :options

  def initialize(steps, options = {})
    @steps = steps
    @options = options
    suggested_step = @steps.find {|step| not step.complete? }
    suggested_step.suggested = true if suggested_step
  end

  def complete?
    steps.all?(&:complete?)
  end

  # Tutorial step subclasses must define a renderer and complete? methods
  class TutorialStep
    attr_accessor :suggested

    def initialize(user)
      @user = user
    end

    def suggested?
      @suggested
    end

    # probably move these next two methods to an exhibit at some point
    def i18n_scope
      "tutorial_bar.#{renderer}"
    end

    def renderer
      "tutorial_#{self.action}_step"
    end
  end

  class LikeStep < TutorialStep
    def action; :like end

    def complete?
      @complete ||= @user.lover?
    end
  end

  class CommentStep < TutorialStep
    def action; :comment end

    def complete?
      @complete ||= @user.commenter?
    end
  end

  class InviteStep < TutorialStep
    def action; :invite end

    def complete?
      @complete =
        if @user.person.connected_to?(:facebook)
          @user.inviter?
        else
          true
        end
    end
  end
end

