require "spec_helper"

describe PullRequest do
  describe "#valid?" do
    context "when payload action is opened" do
      it "returns true" do
        payload = double(:payload, action: "opened")
        pull_request = PullRequest.new(payload, "token")

        expect(pull_request).to be_valid
      end
    end

    context "when payload action is not opened" do
      it "returns false" do
        payload = double(:payload, action: "notopened")
        pull_request = PullRequest.new(payload, "token")

        expect(pull_request).not_to be_valid
      end
    end

    context "when payload action is synchronize" do
      it "returns true" do
        payload = double(:payload, action: "synchronize")
        pull_request = PullRequest.new(payload, "token")

        expect(pull_request).to be_valid
      end
    end

    context "when payload action is not synchronize" do
      it "returns false" do
        payload = double(:payload, action: "notsynchronize")
        pull_request = PullRequest.new(payload, "token")

        expect(pull_request).not_to be_valid
      end
    end
  end

  describe "#config" do
    context "when config file is present" do
      it "returns the contents of custom config" do
        api = double(:github_api, file_contents: "test")
        pull_request = pull_request(api)

        config = pull_request.config

        expect(config).to eq("test")
      end
    end

    context "when config file is not present" do
      it "returns nil" do
        api = double(:github_api)
        api.stub(file_contents: nil)
        pull_request = pull_request(api)
        config = pull_request.config

        expect(config).to be_nil
      end
    end
  end

  def pull_request(api)
    payload = double(
      :payload,
      number: 1,
      full_repo_name: "org/repo",
      head_sha: "abc123"
    )
    GithubApi.stub(new: api)
    PullRequest.new(payload, "gh-token")
  end
end
