class Commenter
  def comment_on_violations(file_violations)
    file_violations.each do |file_violation|
      commit = file_violation.commit
      existing_comments = commit.comments

      file_violation.line_violations.each do |line_violation|
        line = line_violation.line
        previous_comments = previous_line_comments(
          existing_comments,
          line.patch_position,
          file_violation.filename
        )

        if commenting_policy.comment_permitted?(commit, previous_comments, line_violation)
          commit.add_comment(
            file_violation.filename,
            line.patch_position,
            line_violation.messages.join('<br>')
          )
        end
      end
    end
  end

  private

  def commenting_policy
    CommentingPolicy.new
  end

  def previous_line_comments(existing_comments, line_patch_position, filename)
    existing_comments.select do |comment|
      pos = comment.original_position || comment.position
      pos == line_patch_position && comment.path == filename
    end
  end
end
