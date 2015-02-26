class RepoSynchronizationJob < ActiveJob::Base
  extend Retryable

  queue_as :high

  def perform(user, github_token)
    synchronization = RepoSynchronization.new(user, github_token)
    synchronization.start
    user.update_attribute(:refreshing_repos, false)
  rescue Resque::TermException
    retry_job
  rescue => exception
    Rollbar.log(exception, user: { id: user.id })
  end
end
