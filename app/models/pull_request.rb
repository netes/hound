class PullRequest < Event
  def files
    head_commit.files
  end

  def valid?
    opened? || synchronize?
  end

  private

  def head_commit
    @head_commit ||= Commit.new(full_repo_name, @payload.head_sha, api, @payload.number)
  end

  def build_commit_file(file)
    CommitFile.new(file, head_commit)
  end

  def opened?
    @payload.action == 'opened'
  end

  def synchronize?
    @payload.action == 'synchronize'
  end
end
