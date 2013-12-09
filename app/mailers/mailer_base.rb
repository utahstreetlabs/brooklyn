class MailerBase < ActionMailer::Base
  include SendGrid
  include Brooklyn::Instrumentation
  include Brooklyn::Email
  include Brooklyn::ABTesting
  include Stats::Trackable

  attr_reader :link_params, :subject_split_test
  helper :mailer, :application, :users
  default from: from_email

  def initialize(*)
    @link_params = {}
    super
  end

  # Indicates that links in the generated email should include Google Analytics parameters.
  #
  # Example:
  #
  #    def welcome
  #      google_analytics source: 'notifications', campaign: 'welcome'
  #      setup_mail(:welcome)
  #    end
  #
  # @param [Hash] options
  # @option options [String] :source the GA link source (generally the same for every mailer method in a particular
  #   mailer, but not required)
  # @option options [String] :compaign the GA campaign (different for every mailer method)
  def google_analytics(options = {})
    @link_params['utm_medium'] = 'email'
    options.each {|kv| @link_params["utm_#{kv[0]}"] = kv[1]}
  end

  # Sets up split testing identity and success metric
  # Vanity's +_identity+ and +_track+ params to pass the split test name back to the application on clickthrough.
  #
  # If for some reason the visitor id is +nil+, the test is skipped.
  #
  # Example:
  #
  #    def welcome(visitor_id)
  #      split_test_with visitor_id, 'awesomer_explosions'
  #      setup_mail(:welcome)
  #    end
  #
  # @param [String] visitor_id the id of the visitor participating in the test (generally the +User.visitor_id+ for
  #   the recipient of the user)
  # @param [String] metric_name the name of the metric to track
  #   when judging success
  # @see #choose_subject
  def split_test_with(visitor_id, metric_name = 'clickthroughs')
    if visitor_id
      use_vanity_mailer visitor_id
      @link_params['_track'] = metric_name.to_s
      @link_params['_identity'] = visitor_id
    else
      logger.error("Nil visitor id provided to #{self.class}.split_test_with; skipping test")
    end
  end

  # Returns a mail message for the given action.
  #
  # @param [Symbol] action
  # @param [Hash] options
  # @option options [Hash] :headers specifies a hash of custom headers to add to and/or override those computed by
  #   default
  # @option options [Hash] :params a hash of parameters used for variable substitution in the subject translation
  # @see #choose_subject
  # @see #mail
  def setup_mail(action, options = {})
    headers = options.fetch(:headers, {})
    headers[:subject] ||= choose_subject(options.fetch(:subject_ab_test_key, action), options.fetch(:params, {}))
    fire_user_notification_event(:email, {type: "#{mailer_name}##{action}", to: headers[:to]})
    mail(headers)
  end

  # Computes a subject for the message.
  #
  # When split testing has been indicated with +#split_test_with+, a
  # test alternative is chosen and used as the locale key. Additionally, +.subject+ is appended to the
  # base scope. For example, if a test has two alternatives called
  # "ham" and "jam", then the possible subject keys are:
  #
  # * +mailers.<mailer_name>.<action>.subject.ham
  # * +mailers.<mailer_name>.<action>.subject.jam
  #
  # Without split testing, the subject key is +mailers.<mailer_name>.<action>.subject+.
  #
  # @param [Symbol] action
  # @param [Hash] options
  # @option options [Hash] :params a hash of parameters used for variable substitution in the subject translation
  # @see #mailer_name
  # @see SplitTest
  def choose_subject(action, params = {})
    scope = [:mailers, mailer_name, action]
    key = :subject
    experiment_name = "#{mailer_name}_mailer_#{action}_subject".to_sym
    if experiment_active?(experiment_name)
      scope << key
      key = ab_test(experiment_name)
    end
    params.merge!(scope: scope)
    I18n.t(key, params)
  end

  def mailer_name
    self.class.name.underscore.gsub(/_mailer$/, '')
  end

  # convert attrs hash to HashWithIndifferentAccess to work around
  # differences between performing mailer jobs inline and performing
  # them through resque - inline they use the symbol keys from
  # to_job_hash, through resque they end up with string keys
  def attrs_hash(attrs)
    HashWithIndifferentAccess.new(attrs)
  end

  class << self
    def method_missing(name, *args)
      return super unless respond_to?(name)
      msg = new(name, *args).message
      to = User.formatted_mailable_addresses(msg.to)
      if to.any?
        msg.to = to.join(', ')
        msg
      else
        MessageWithNoRecipient.new
      end
    end
  end

  # Class with a stubbed deliver method. It is returned when a Message has no valid recipients so that the email does
  # not get sent.
  class MessageWithNoRecipient
    def deliver; end
  end
end
