require "new_relic_logger/host"

module NewRelicLogger
  class ConfigurationError < StandardError; end

  class << self
    def new(options = {})
      license_key = options[:license_key]  || ENV['NEW_RELIC_LICENSE_KEY']
      region      = options[:region]       || ENV['NEW_RELIC_LOGGING_REGION']

      verify_params(license_key, region)

      NewRelic::Agent::Logging::DecoratingLogger.new(NewRelicLogger::Host.new(license_key, region))
    end

    def verify_params(license_key, region)
      raise NewRelicLogger::ConfigurationError.new('License key is required') if license_key&.empty?
      raise NewRelicLogger::ConfigurationError.new('Invalid region') unless NewRelicLogger::Host::REGIONS.key?(region)
    end
  end
end
