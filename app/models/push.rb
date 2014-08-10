class Push < Event
  def files
    commits.flat_map do |commit|
      commit.files
    end
  end

  def valid?
    true
  end

  private

  def head_commit
    commits.first
  end

  def commits
    @commits ||= @payload.commits.map do |commit_data|
      Commit.new(full_repo_name, commit_data['id'], api)
    end
  end
end
