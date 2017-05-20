# frozen_string_literal: true
require "bump/dependency_metadata_finders"

module Bump
  class DependencyFilePusher
    attr_reader :repo_name, :dependency, :files, :base_commit, :github_client,
                :target_branch

    def initialize(repo:, base_commit:, dependency:, files:, github_client:,
                   target_branch: nil)
      @dependency = dependency
      @repo_name = repo
      @base_commit = base_commit
      @files = files
      @github_client = github_client
      @target_branch = target_branch
    end

    def create
      return if branch_exists? && !updating_existing_branch?
      raise "Branch not found" if updating_existing_branch? && !branch_exists?

      commit = create_commit

      updating_existing_branch? ? update_branch(commit) : create_branch(commit)
    end

    private

    def branch_exists?
      return @branch_exists unless @branch_exists.nil?
      branch_name = updating_existing_branch? ? target_branch : new_branch_name
      github_client.ref(repo_name, "heads/#{branch_name}")
      @branch_exists = true
    rescue Octokit::NotFound
      @branch_exists = false
    end

    def updating_existing_branch?
      !target_branch.nil?
    end

    def create_commit
      tree = create_tree

      github_client.create_commit(
        repo_name,
        commit_message,
        tree.sha,
        base_commit
      )
    end

    def create_tree
      file_trees = files.map do |file|
        {
          path: file.path.sub(%r{^/}, ""),
          mode: "100644",
          type: "blob",
          content: file.content
        }
      end

      github_client.create_tree(
        repo_name,
        file_trees,
        base_tree: base_commit
      )
    end

    def create_branch(commit)
      github_client.create_ref(
        repo_name,
        "heads/#{new_branch_name}",
        commit.sha
      )
    rescue Octokit::UnprocessableEntity => error
      # Return quietly in the case of a race
      return nil if error.message =~ /Reference already exists/
      raise
    end

    def update_branch(commit)
      github_client.update_ref(
        repo_name,
        "heads/#{target_branch}",
        commit.sha,
        true
      )
    end

    def commit_message
      commit_message_title + "\n\n" + commit_message_body
    end

    def commit_message_title
      msg = "Bump #{dependency.name} to #{dependency.version}"
      files.first.directory == "/" ? msg : msg + " in #{files.first.directory}"
    end

    def commit_message_body
      msg =
        if github_repo_url
          "Bumps [#{dependency.name}](#{github_repo_url}) "
        else
          "Bumps #{dependency.name} "
        end

      if dependency.previous_version
        msg += "from #{dependency.previous_version} "
      end

      msg += "to #{dependency.version}."
      msg += "\n- [Release notes](#{release_url})" if release_url
      msg += "\n- [Changelog](#{changelog_url})" if changelog_url
      msg += "\n- [Commits](#{github_compare_url})" if github_compare_url
      msg
    end

    def default_branch
      @default_branch ||= github_client.repository(repo_name).default_branch
    end

    def new_branch_name
      path = ["bump", dependency.language, files.first.directory].compact
      File.join(*path, "#{dependency.name}-#{dependency.version}")
    end

    def release_url
      dependency_metadata_finder.release_url
    end

    def changelog_url
      dependency_metadata_finder.changelog_url
    end

    def github_compare_url
      dependency_metadata_finder.github_compare_url
    end

    def github_repo_url
      dependency_metadata_finder.github_repo_url
    end

    def dependency_metadata_finder
      @dependency_metadata_finder ||=
        DependencyMetadataFinders.for_language(dependency.language).
        new(dependency: dependency, github_client: github_client)
    end
  end
end
