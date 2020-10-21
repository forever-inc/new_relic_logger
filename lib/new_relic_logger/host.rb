require 'net/http'
require "new_relic_logger/log_queue"

module NewRelicLogger
  class Host
    REGIONS = {
      'us' => URI('https://log-api.newrelic.com/log/v1'),
      'eu' => URI('https://log-api.eu.newrelic.com/log/v1')
    }

    QUEUE_SIZE         = ENV.fetch('NEW_RELIC_LOGGING_QUEUE_SIZE') { 100 }.to_i
    QUEUE_WAIT_TIMEOUT = ENV.fetch('NEW_RELIC_LOGGING_QUEUE_WAIT_TIMEOUT') { 30 }.to_i

    LOGS_PAYLOAD       = [{ logs: [] }].to_json.freeze
    LOGS_PAYLOAD_REGEX = /(\[\])/.freeze
    OPEN_BRACKET       = '['.freeze
    CLOSE_BRACKET      = ']'.freeze

    STOP_MAX_WAIT  = 10 # max seconds to wait for queue shutdown clearing
    STOP_WAIT_STEP = 0.2 # sleep duration (seconds) while shutting down

    def initialize(license_key, region)
      @license_key  = license_key
      @region       = region

      @queue   = NewRelicLogger::LogQueue.new(QUEUE_SIZE)
      @thread  = nil

      at_exit { stop }
    end

    def write(message)
      @queue << message

      @thread = Thread.new { run } unless @thread&.alive?
    end

    def run
      loop do
        messages = @queue.pop_with_timeout(QUEUE_WAIT_TIMEOUT)
        logs     = LOGS_PAYLOAD.gsub(LOGS_PAYLOAD_REGEX, messages.join(',').prepend(OPEN_BRACKET).concat(CLOSE_BRACKET))

        response = Net::HTTP.post(REGIONS[@region], logs, headers)

        begin
          response.value # raises an error if the post was unsuccessful
        rescue => e
          NewRelic::Agent.notice_error(e)
        end
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
      @queue.close

      STOP_MAX_WAIT.div(STOP_WAIT_STEP).times do
        break if @queue.empty?

        sleep STOP_WAIT_STEP
      end

      @thread&.exit
    end
  end
end
