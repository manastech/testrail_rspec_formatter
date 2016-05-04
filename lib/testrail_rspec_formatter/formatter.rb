require "rspec"
require "rspec/core/formatters/base_text_formatter"

require "testrail_rspec_formatter/client"
require "testrail_rspec_formatter/formatter"

RSpec.configuration.add_setting :testrail_formatter_options, :default => {}

module TestrailRspecFormatter
  class Formatter < ::RSpec::Core::Formatters::BaseTextFormatter
    PASSED = 1
    BLOCKED = 2
    UNTESTED = 3
    RETEST = 4
    FAILED = 5

    RSpec::Core::Formatters.register self, :start, :close, :dump_summary, :dump_failures, :dump_pending

    def dump_summary(notification)
      examples = notification.examples
      results = []
      examples.each do |example|
        next if example.pending?

        testrail_metadata = example.metadata[:testrail]
        next unless testrail_metadata

        result = {
          case_id: testrail_metadata,
          status_id: testrail_status(example),
        }
        results << result
      end

      unless results.empty?
        post_testrail_results(results)
      end
    end

    def dump_failures(*)
      # Nothing
    end

    def dump_pending(*)
      # Nothing
    end

    private

    def post_testrail_results(results)
      client = new_testrail_client
      run_id = testrail_config_value(:run_id, "TESTRAIL_FORMATTER_RUN_ID")

      json = {results: results}
      client.send_post("add_results_for_cases/#{run_id}", json)
    end

    def new_testrail_client
      client = APIClient.new(testrail_config_value(:url, "TESTRAIL_FORMATTER_URL"))
      client.user = testrail_config_value(:user, "TESTRAIL_FORMATTER_USER")
      client.password = testrail_config_value(:password, "TESTRAIL_FORMATTER_PASSWORD")
      client
    end

    def testrail_config_value(hash_key, env_key)
      RSpec.configuration.testrail_formatter_options[hash_key] || ENV[env_key] || raise("Missing RSpec.configuration.testrail_formatter_options[#{hash_key.inspect}] or ENV[#{env_key.inspect}]")
    end

    def testrail_status(example)
      case example.execution_result.status
      when :passed
        PASSED
      else
        FAILED
      end
    end
  end
end