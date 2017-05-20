# frozen_string_literal: true
require "bump/dependency_metadata_finders"

module Bump
  class PullRequestCreator
    attr_reader :repo_name, :branch_name, :github_client, :pr_message_footer

    def initialize(repo_name:, branch_name:, github_client:,
                   pr_message_footer: nil)
      @repo_name = repo_name
      @branch_name = branch_name
      @github_client = github_client
      @pr_message_footer = pr_message_footer
    end

    def create
      github_client.create_pull_request(
        repo_name,
        target_branch,
        branch_name,
        pr_name,
        pr_message
      )
    end

    private

    def pr_name
      commit.message.split("\n\n").first
    end

    def pr_message
      message = commit.message.split("\n\n")[1..-1].join("\n\n")

      return message unless pr_message_footer
      message + "\n\n#{pr_message_footer}"
    end

    def commit
      @branch ||= github_client.branch(repo_name, branch_name).commit.commit
    end

    def target_branch
      @default_branch ||= github_client.repository(repo_name).default_branch
    end
  end
end
