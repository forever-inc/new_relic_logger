require 'net/http'

module NewRelicLogger
  class Host
    STOP_MESSAGE   = :stop
    STOP_MAX_WAIT  = 10 # max seconds to wait for queue shutdown clearing
    STOP_WAIT_STEP = 0.2 # sleep duration (seconds) while shutting down

    REGIONS = {
      'us' => URI('https://log-api.newrelic.com/log/v1'),
      'eu' => URI('https://log-api.eu.newrelic.com/log/v1')
    }

    def initialize(license_key, region)
      @license_key  = license_key
      @region       = region

      @queue   = Queue.new
      @thread  = nil

      at_exit { stop }
    end

    def write(message)
      @queue << message

      @thread = Thread.new { run } unless @thread&.alive?
    end

    def run
      loop do
        message = @queue.pop
        break if message == STOP_MESSAGE

        Net::HTTP.post(REGIONS[@region], { service: ENV['NEW_RELIC_APP_NAME'], message: message }.to_json, headers)
      end
    end

    def close
      # no-op
    end

    private

    def headers
      @headers ||= { 'Content-Type' => 'application/json', 'X-License-Key' => @license_key }
    end

    def stop
      @queue << STOP_MESSAGE

      STOP_MAX_WAIT.div(STOP_WAIT_STEP).times do
        break if @queue.empty?

        sleep STOP_WAIT_STEP
      end

      @queue.close
      @thread&.exit
    end
  end
end
