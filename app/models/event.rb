class Event
  CONFIG_FILE = '.hound.yml'

  def initialize(payload, github_token)
    @payload = payload
    @github_token = github_token
  end

  def config
    head_commit.file_content(CONFIG_FILE)
  end

  private

  def api
    @api ||= GithubApi.new(@github_token)
  end

  def full_repo_name
    @payload.full_repo_name
  end

  def self.new_from_payload(payload, github_token)
    (payload.pull_request? ? PullRequest : Push).new(payload, github_token)
  end
end
