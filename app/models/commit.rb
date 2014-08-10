class Commit
  attr_reader :full_repo_name, :sha

  def initialize(full_repo_name, sha, github, pull_request_number = nil)
    @full_repo_name = full_repo_name
    @sha = sha
    @github = github
    @pull_request_number = pull_request_number
  end

  def files
    @files ||= github_files.map { |file| build_commit_file(file) }
  end

  def file_content(filename)
    @github.file_contents(@full_repo_name, filename, sha)
  end

  def add_comment(filename, patch_position, message)
    @github.add_comment(
      comment: message,
      commit: self,
      filename: filename,
      patch_position: patch_position,
      pull_request_number: @pull_request_number,
    )
  end

  def comments
    @comments ||= if @pull_request_number
      @github.pull_request_comments(full_repo_name, @pull_request_number)
    else
      @github.commit_comments(full_repo_name, sha)
    end
  end

  def includes?(line)
    files.any?{ |file| file.modified_lines.include?(line) }
  end

  private

  def build_commit_file(file)
    CommitFile.new(file, self)
  end

  def github_files
    if @pull_request_number
      @github.pull_request_files(full_repo_name, @pull_request_number)
    else
      @github.commit_files(full_repo_name, sha)
    end
  end
end
