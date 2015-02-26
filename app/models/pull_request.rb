class PullRequest < Event
  def commits
    [head_commit]
  end

  def relevant?
    super && (opened? || synchronize?)
  end

  def repository_owner_name
    payload.repository_owner_name
  end

  def opened?
    payload.action == "opened"
  end

  def synchronize?
    payload.action == "synchronize"
  end

  private

  def head_commit
    Commit.new(full_repo_name, payload.head_sha, api,
      pull_request_number: payload.pull_request_number,
      repository_owner_name: payload.repository_owner_name)
  end
end
