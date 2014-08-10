require 'json'

class Payload
  attr_reader :data

  def initialize(data)
    if data.is_a? String
      @data = JSON.parse(data)
    else
      @data = data
    end
  end

  def github_repo_id
    data['repository']['id']
  end

  def full_repo_name
    data['repository']['full_name']
  end

  def head_sha
    pull_request.fetch("head", {})["sha"]
  end

  def number
    data['number']
  end

  def action
    data['action']
  end

  def changed_files
    if pull_request?
      pull_request["changed_files"] || 0
    else
      commits.sum do |c|
        c['added'].count + c['modified'].count + c['removed'].count
      end
    end
  end

  def commits
    data['commits'] || []
  end

  def ping?
    data['zen']
  end

  def pull_request?
    data.has_key?('pull_request')
  end

  private

  def pull_request
    data.fetch("pull_request", {})
  end
end
