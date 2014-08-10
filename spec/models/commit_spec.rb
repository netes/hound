require "fast_spec_helper"
require "octokit"
require "app/models/commit"

describe Commit do
  describe "#file_content" do
    context "when content is returned from GitHub" do
      it "returns content" do
        file_contents = "some content"
        github = double(:github_api, file_contents: file_contents)
        commit = Commit.new("test/test", "abc", github)

        expect(commit.file_content("test.rb")).to eq "some content"
      end
    end

    context "when nothing is returned from GitHub" do
      it "returns nil" do
        github = double(:github_api, file_contents: nil)
        commit = Commit.new("test/test", "abc", github)

        expect(commit.file_content("test.rb")).to eq nil
      end
    end

    context "when content is nil" do
      it "returns nil" do
        contents = nil
        github = double(:github_api, file_contents: contents)
        commit = Commit.new("test/test", "abc", github)

        expect(commit.file_content("test.rb")).to eq nil
      end
    end

    describe "#comments" do
      it "returns comments on pull request" do
        patch_position = 7
        filename = "spec/models/style_guide_spec.rb"
        comment = double(:comment, position: patch_position, path: filename)
        github = double(:github_api, pull_request_comments: [comment])
        commit = Commit.new("test/test", "abc", github, 1)

        comments = commit.comments

        expect(comments).to have(1).item
        expect(comments).to match_array([comment])
      end
    end

    describe "#add_comment" do
      it "posts a comment to GitHub for the Hound user" do
        github = double(:github_client, add_comment: nil)
        commit = Commit.new("test/test", "abc", github, 1)

        commit.add_comment("test.rb", 123, "A comment")

        expect(github).to have_received(:add_comment).with(
          pull_request_number: 1,
          commit: commit,
          comment: "A comment",
          filename: "test.rb",
          patch_position: 123
        )
      end
    end
  end
end
