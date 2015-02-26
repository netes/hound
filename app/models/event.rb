class Event
  pattr_initialize :payload

  def relevant?
    commits.any? && config.enabled_for?(name)
  end

  def files
    commits.flat_map do |commit|
      commit.files
    end
  end

  def config
    @config ||= RepoConfig.new(head_commit)
  end

  def repository_owner_name
    payload.repository_owner_name
  end

  private

  def api
    @api ||= GithubApi.new(ENV["HOUND_GITHUB_TOKEN"])
  end

  def full_repo_name
    payload.full_repo_name
  end

  def self.new_from_payload(payload)
    (payload.pull_request? ? PullRequest : Push).new(payload)
  end

  def name
    self.class.name.pluralize.underscore
  end
end
