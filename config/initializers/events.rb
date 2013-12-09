require 'brooklyn/logger'
require 'brooklyn/event_log'

Brooklyn::EventLog.logger = Brooklyn::Logger.new(
  use_syslog:   Brooklyn::Application.config.event_logging.use_syslog,
  log_file:     Brooklyn::Application.config.event_logging.log_file,
  log_facility: Brooklyn::Application.config.event_logging.log_facility,
  log_level:    Brooklyn::Application.config.event_logging.log_level,
  log_name:     Brooklyn::Application.config.event_logging.log_name)

Brooklyn::EventLog.setup

if (Brooklyn::EventLog.logger.use_syslog?) 
  Rails.logger.info("Tracking events to syslog (facility=>#{Brooklyn::Application.config.event_logging.log_facility},level=>#{Brooklyn::Application.config.event_logging.log_level},name=>#{Brooklyn::Application.config.event_logging.log_name})")
else
  Rails.logger.info("Tracking events to file (log_file=>#{Brooklyn::Application.config.event_logging.log_file},level=>#{Brooklyn::Application.config.event_logging.log_level},name=>#{Brooklyn::Application.config.event_logging.log_name})")
end
