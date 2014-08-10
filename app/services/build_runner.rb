class BuildRunner
  attr_reader :payload

  def initialize(payload)
    @payload = payload
  end

  def run
    if repo && event.valid?
      commenter.comment_on_violations(violations)
    end
  end

  private

  def violations
    @violations ||= style_checker.violations
  end

  def style_checker
    StyleChecker.new(event.files, event.config)
  end

  def commenter
    Commenter.new
  end

  def event
    @event ||= Event.new_from_payload(payload, ENV['HOUND_GITHUB_TOKEN'])
  end

  def repo
    @repo ||= Repo.active.where(github_id: payload.github_repo_id).first
  end
end
