# frozen_string_literal: true
require "bump/dependency_file"
require "bump/errors"

module Bump
  module FileFetchers
    class Base
      attr_reader :repo, :github_client, :directory

      def self.required_files
        raise NotImplementedError
      end

      def initialize(repo:, github_client:, directory: "/")
        @repo = repo
        @github_client = github_client
        @directory = directory
      end

      def files
        @files ||= self.class.required_files.map do |name|
          fetch_file_from_github(name)
        end
      end

      def commit
        default_branch = github_client.repository(repo.name).default_branch
        github_client.ref(repo.name, "heads/#{default_branch}").object.sha
      end

      private

      def fetch_file_from_github(file_name)
        file_path = File.join(directory, file_name)
        content = github_client.contents(repo.name, path: file_path).content
        decoded_content = Base64.decode64(content)

        # Removes path based depedencies

        pathless_content = decoded_content.lines.reject do |line|
          line.include?("path")
        end.join

        DependencyFile.new(
          name: file_name,
          content: pathless_content,
          directory: directory
        )
      rescue Octokit::NotFound
        raise Bump::DependencyFileNotFound, file_path
      end
    end
  end
end
