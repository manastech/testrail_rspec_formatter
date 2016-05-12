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
      disabled = testrail_config_value(:disabled, "TESTRAIL_FORMATTER_DISABLED", false)
      if disabled == "1" || disabled == true
        testrail_log "skipped because it was disabled"
        return
      end

      testrail_log "starting..."

      examples = notification.examples
      results = []
      examples.each do |example|
        testrail_metadata = example.metadata[:testrail]
        next unless testrail_metadata

        result = {
          case_id: testrail_metadata,
          status_id: testrail_status(example),
        }
        results << result
      end

      if results.empty?
        testrail_log "no test cases found (no spec had a testrail tag)"
      else
        post_testrail_results(results)
      end
    ensure
      testrail_log "finished"
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

      project_id = testrail_config_value(:project_id, "TESTRAIL_FORMATTER_PROJECT_ID")
      run_name = testrail_config_value(:run_name, "TESTRAIL_FORMATTER_RUN_NAME")

      testrail_log "target url is: #{client.base_url}"

      runs = client.get("get_runs/#{project_id}")
      run = runs.find { |run| run["name"] == run_name }
      if run
        run_id = run["id"]
        testrail_log "found run with name #{run_name.inspect}, id is #{run["id"]}"
      else
        testrail_log "no run found with name #{run_name.inspect}, creating one..."
        case_ids = results.map { |result| result[:case_id] }
        run = client.post("add_run/#{project_id}", {
          name: run_name,
          include_all: false,
          case_ids: case_ids,
        })
        run_id = run["id"]
        testrail_log "created run with id #{run["id"]}"
      end

      testrail_log "sending results for #{results.size} test case#{results.size == 1 ? "" : "s"}..."

      client.post("add_results_for_cases/#{run_id}", {results: results})
    end

    def new_testrail_client
      client = APIClient.new(testrail_config_value(:url, "TESTRAIL_FORMATTER_URL"))
      client.user = testrail_config_value(:user, "TESTRAIL_FORMATTER_USER")
      client.password = testrail_config_value(:password, "TESTRAIL_FORMATTER_PASSWORD")
      client
    end

    def testrail_config_value(hash_key, env_key, default = nil)
      value = RSpec.configuration.testrail_formatter_options[hash_key] || ENV[env_key]
      if !value && default == nil
        raise("Missing RSpec.configuration.testrail_formatter_options[#{hash_key.inspect}] or ENV[#{env_key.inspect}]")
      end
      value || default
    end

    def testrail_status(example)
      case
      when example.pending?
        RETEST
      when example.execution_result.status == :passed
        PASSED
      else
        FAILED
      end
    end

    def testrail_log(message)
      output.puts "TestRail: #{message}"
    end
  end
end