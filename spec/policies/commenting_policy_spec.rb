require 'fast_spec_helper'
require 'app/policies/commenting_policy'

describe CommentingPolicy do
  describe '#comment_permitted?' do
    context 'when violation has not previously been reported' do
      context 'when pull request head does not include the given line' do
        it 'returns false' do
          commit = stubbed_commit(
            includes?: false,
          )
          line_violation = stubbed_line_violation
          previous_comments_for_line = []
          commenting_policy = CommentingPolicy.new

          result = commenting_policy.comment_permitted?(
            commit,
            previous_comments_for_line,
            line_violation
          )

          expect(result).to be_false
        end
      end

      context 'when pull request head includes the given line' do
        it 'returns true' do
          commit = stubbed_commit
          line_violation = stubbed_line_violation
          previous_comments_for_line = []
          commenting_policy = CommentingPolicy.new

          result = commenting_policy.comment_permitted?(
            commit,
            previous_comments_for_line,
            line_violation
          )

          expect(result).to be_true
        end
      end
    end

    context 'when a comment reporting the violation has already been made' do
      it 'returns false' do
        existing_comment_message = 'Trailing whitespace detected<br>Extra newline'
        violation_message = 'Trailing whitespace detected'
        line_violation = stubbed_line_violation([violation_message])
        commit = stubbed_commit
        comment = double(:comment, body: existing_comment_message)
        previous_comments_on_line = [comment]
        commenting_policy = CommentingPolicy.new

        result = commenting_policy.comment_permitted?(
          commit,
          previous_comments_on_line,
          line_violation
        )

        expect(result).to be_false
      end
    end
  end

  def stubbed_line_violation(messages = [])
    double(
      :line_violation,
      line: double(:line),
      messages: messages
    )
  end

  def stubbed_commit(options = { includes?: true })
    double(
      includes?: options[:includes?],
      files: [],
      comments: [],
    )
  end
end
