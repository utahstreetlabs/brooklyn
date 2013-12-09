require "sunspot/rails"
require "sunspot/rails/solr_logging"

config = YAML.load_file("#{Rails.root}/config/sunspot.yml")[Rails.env]['solr']

Rails.logger.info("Searching indexes with Solr at #{config['hostname']}:#{config['port']}")
