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

      def files(&blk)
        @files ||= self.class.required_files.map do |name|
          fetch_file_from_github(name, &blk)
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
        decoded_file = Base64.decode64(content)

        depedency_file_content = if block_given?
                                   yield(decoded_file)
                                 else
                                   decoded_file
                                 end

        DependencyFile.new(
          name: file_name,
          content: depedency_file_content,
          directory: directory
        )
      rescue Octokit::NotFound
        raise Bump::DependencyFileNotFound, file_path
      end
    end
  end
end
