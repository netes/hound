class BuildRunner
  MAX_COMMENTS = ENV.fetch("MAX_COMMENTS").to_i

  pattr_initialize :payload

  def run
    if repo && event.relevant?
      track_subscribed_build_started
      create_pending_status
      each_commit_violations do |commit, violations|
        repo.builds.create!(
          violations: violations,
          pull_request_number: payload.pull_request_number,
          commit_sha: commit.sha,
        )
        Commenter.new(commit).comment_on_violations(priority_violations(violations))
      end
      create_success_status
      upsert_owner
      track_subscribed_build_completed
    end
  end

  private

  def each_commit_violations
    event.commits.each do |commit|
      yield commit, StyleChecker.new(commit, event.config).violations
    end
  end

  def event
    @event ||= Event.new_from_payload(payload)
  end

  def priority_violations(violations)
    violations.take(MAX_COMMENTS)
  end

  def repo
    @repo ||= Repo.active.
      find_and_update(payload.github_repo_id, payload.full_repo_name)
  end

  def track_subscribed_build_started
    if repo.subscription
      user = repo.subscription.user
      analytics = Analytics.new(user)
      analytics.track_build_started(repo)
    end
  end

  def track_subscribed_build_completed
    if repo.subscription
      user = repo.subscription.user
      analytics = Analytics.new(user)
      analytics.track_build_completed(repo)
    end
  end

  def create_pending_status
    github.create_pending_status(
      payload.full_repo_name,
      payload.head_sha,
      "Hound is reviewing changes."
    )
  end

  def create_success_status
    github.create_success_status(
      payload.full_repo_name,
      payload.head_sha,
      "Hound has reviewed the changes."
    )
  end

  def upsert_owner
    Owner.upsert(
      github_id: payload.repository_owner_id,
      name: payload.repository_owner_name,
      organization: payload.repository_owner_is_organization?
    )
  end

  def github
    @github ||= GithubApi.new(ENV["HOUND_GITHUB_TOKEN"])
  end
end
