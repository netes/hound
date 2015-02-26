module Buildable
  def perform(payload_data)
    payload = Payload.new(payload_data)
    build_runner = BuildRunner.new(payload)
    build_runner.run
  rescue Resque::TermException
    retry_job
  rescue => exception
    Rollbar.log(exception, payload: { data: payload_data })
  end
end
