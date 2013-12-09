require 'active_support'
require 'syslog'
require 'logger'

module Brooklyn
  module Log
    LOG_LEVELS = {
      :'<<' => Syslog::LOG_ALERT,
      :crit => Syslog::LOG_CRIT,
      :emerg => Syslog::LOG_EMERG,
      :alert => Syslog::LOG_ALERT,
      :error => Syslog::LOG_ERR,
      :warn => Syslog::LOG_WARNING,
      :notice => Syslog::LOG_NOTICE,
      :info => Syslog::LOG_INFO,
      :debug => Syslog::LOG_DEBUG
    }

    LOG_LEVELS.each do |name,level|
      code = %Q{
        def #{name}(*args)
          self.log(#{level}, args.first, args.slice(1..-1)) if args.any?
          self.log(#{level}, yield) if block_given?
        end
      }
      class_eval(code)
    end

    def use_syslog?
      !use_syslog.nil? && (use_syslog != 0) && (use_syslog != false)
    end

    def use_logfile?
      !log_file.nil? && (log_file != '') && (log_file != false)
    end
    
    def log_string(priority, message, *rest)
      "[#{priority2string(priority)}]: [#{LogWeasel::Transaction.id}] #{message} #{rest.join(',')}"
    end

    def log(priority, message, *rest)
      if (priority <= self.log_level)
        if self.use_syslog?
          begin
            Syslog.open(ident=self.log_name,
                        logopt = Syslog::LOG_PID|Syslog::LOG_CONS,
                        facility = self.log_facility) do
            
              # timestamp is included in syslog by default
              Syslog.log(priority, log_string(priority, message, *rest))
            end
          rescue Exception => e
            $stderr.puts "Could not log to syslog: #{e}"
          end
        elsif self.use_logfile?
          begin
            # Attempt to open logfile if not already open
            if !self.lfd.present?
              self.lfd = File.open(self.log_file, "a+") 
              self.lfd.sync = true
            end

            self.lfd.puts "#{Time.new} #{self.log_name} #{log_string(priority, message, *rest)}"
          rescue Exception => e
            $stderr.puts "Could not log to file: #{e}"
          end
        else
          # Just print to stderr
          $stderr.puts "#{Time.new} #{self.log_name} #{log_string(priority, message, *rest)}"
        end
      end
    end

    def close
      if Syslog.opened?
        Syslog.close
      end
      if self.lfd.present?
        self.lfd.close
      end
    end

    def priority2string(priority)
      if priority == Syslog::LOG_CRIT
        "CRIT"
      elsif priority == Syslog::LOG_EMERG
        "EMERG"
      elsif priority == Syslog::LOG_ALERT
        "ALERT"
      elsif priority == Syslog::LOG_ERR
        "ERR"
      elsif priority == Syslog::LOG_WARNING
        "WARNING"
      elsif priority == Syslog::LOG_NOTICE
        "NOTICE"
      elsif priority == Syslog::LOG_INFO
        "INFO"
      elsif priority == Syslog::LOG_DEBUG
        "DEBUG"
      end
    end
  end

  class Logger < Logger
    include Brooklyn::Log

    attr_accessor :log_level
    @log_level = Syslog::LOG_ALERT

    attr_accessor :log_facility
    @log_facility = Syslog::LOG_USER

    attr_accessor :log_name
    @log_name = "logger"

    attr_accessor :log_file
    @log_file = nil

    attr_accessor :use_syslog
    @use_syslog = 0

    attr_accessor :lfd
    @lfd = nil

    def initialize(params = {})
      [:use_syslog, :log_facility, :log_name, :log_level, :log_file].each do |key|
        self.instance_variable_set(:"@#{key}", params[key]) if params.key?(key)
      end
      @level = self.log_level

      super(self.log_file) unless self.use_syslog?
    end
  end
end
