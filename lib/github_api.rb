require 'octokit'
require 'base64'

class GithubApi
  SERVICES_TEAM_NAME = 'Services'

  attr_reader :client

  def initialize(token)
    @client = Octokit::Client.new(access_token: token)
  end

  def repos
    user_repos + org_repos
  end

  def add_user_to_repo(username, repo_name)
    repo = repo(repo_name)

    if repo.organization
      add_user_to_org(username, repo)
    else
      client.add_collaborator(repo.full_name, username)
    end
  end

  def repo(repo_name)
    client.repository(repo_name)
  end

  def add_comment(options)
    if options[:pull_request_number]
      add_pull_request_comment(options)
    else
      add_commit_comment(options)
    end
  end

  def create_hook(full_repo_name, callback_endpoint)
    hook = client.create_hook(
      full_repo_name,
      'web',
      { url: callback_endpoint },
      { events: ['push', 'pull_request'], active: true }
    )

    yield hook if block_given?
  rescue Octokit::UnprocessableEntity => error
    unless error.message.include? 'Hook already exists'
      raise
    end
  end

  def remove_hook(full_github_name, hook_id)
    client.remove_hook(full_github_name, hook_id)
  end

  def commit_files(full_repo_name, commit_sha)
    commit = client.commit(full_repo_name, commit_sha)
    commit.files
  end

  def commit_comments(full_repo_name, commit_sha)
    client.commit_comments(full_repo_name, commit_sha)
  end

  def pull_request_comments(full_repo_name, pull_request_number)
    client.pull_request_comments(full_repo_name, pull_request_number)
  end

  def pull_request_files(full_repo_name, number)
    client.pull_request_files(full_repo_name, number)
  end

  def file_contents(full_repo_name, filename, sha)
    contents = client.contents(full_repo_name, path: filename, ref: sha)
    if contents && contents.content
      Base64.decode64(contents.content)
    end
  rescue Octokit::NotFound
    nil
  end

  def user_teams
    client.user_teams
  end

  def email_address
    primary_email = client.emails.detect { |email| email['primary'] }
    primary_email['email']
  end

  private

  def add_commit_comment(options)
    client.create_commit_comment(
      options[:commit].full_repo_name,
      options[:commit].sha,
      options[:comment],
      options[:filename],
      nil,
      options[:patch_position],
    )
  end

  def add_pull_request_comment(options)
    client.create_pull_request_comment(
      options[:commit].full_repo_name,
      options[:pull_request_number],
      options[:comment],
      options[:commit].sha,
      options[:filename],
      options[:patch_position]
    )
  end

  def add_user_to_org(username, repo)
    repo_teams = client.repository_teams(repo.full_name)
    admin_team = admin_access_team(repo_teams)

    if admin_team
      add_user_to_team(username, admin_team.id)
    else
      add_user_and_repo_to_services_team(username, repo)
    end
  end

  def admin_access_team(repo_teams)
    token_bearer = GithubUser.new(self)

    repo_teams.detect do |repo_team|
      token_bearer.has_admin_access_through_team?(repo_team.id)
    end
  end

  def add_user_and_repo_to_services_team(username, repo)
    team = find_team(SERVICES_TEAM_NAME, repo)

    if team
      client.add_team_repository(team.id, repo.full_name)
    else
      team = create_team(SERVICES_TEAM_NAME, repo)
    end

    add_user_to_team(username, team.id)
  end

  def add_user_to_team(username, team_id)
    client.add_team_member(team_id, username)
  end

  def find_team(name, repo)
    teams = client.org_teams(repo.organization.login, per_page: 100)
    until team = teams.find{ |t| t.name == name } || teams.count < 100 do
      teams = client.last_response.rels[:next].get.data
    end
    team
  end

  def create_team(name, repo)
    client.create_team(
      repo.organization.login,
      {
        name: name,
        repo_names: [repo.full_name],
        permission: 'pull'
      }
    )
  end

  def user_repos
    repos = []
    page = 1

    loop do
      results = client.repos(nil, page: page)
      repos.concat(authorized_repos(results))
      break unless results.any?
      page += 1
    end

    repos
  end

  def org_repos
    repos = []

    orgs.each do |org|
      page = 1

      loop do
        results = client.org_repos(org[:login], page: page)
        repos.concat(authorized_repos(results))
        break unless results.any?
        page += 1
      end
    end

    repos
  end

  def orgs
    client.orgs
  end

  def authorized_repos(repos)
    repos.select {|repo| repo.permissions.admin }
  end
end
