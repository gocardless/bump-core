# frozen_string_literal: true
require "bump/dependency"
require "bump/file_parsers/base"
require "bump/file_fetchers/elixir/hex"
require "bump/shared_helpers"

module Bump
  module FileParsers
    module Elixir
      class Hex < Bump::FileParsers::Base
        def parse
          dependency_versions.map do |dep|
            Dependency.new(
              name: dep["name"],
              version: dep["version"],
              language: "elixir"
            )
          end
        end

        private

        def dependency_versions
          SharedHelpers.in_a_temporary_directory do |dir|
            File.write(File.join(dir, "mix.exs"), mixfile.content)
            File.write(File.join(dir, "mix.lock"), lockfile.content)

            SharedHelpers.run_helper_subprocess(
              command: "elixir #{elixir_helper_path}",
              function: "parse",
              args: [dir]
            )
          end
        end

        def elixir_helper_path
          project_root = File.join(File.dirname(__FILE__), "../../../..")
          File.join(project_root, "helpers/elixir/bin/run.exs")
        end

        def required_files
          Bump::FileFetchers::Elixir::Hex.required_files
        end

        def mixfile
          @mixfile ||= get_original_file("mix.exs")
        end

        def lockfile
          @lockfile ||= get_original_file("mix.lock")
        end
      end
    end
  end
end
