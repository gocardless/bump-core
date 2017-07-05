# frozen_string_literal: true
require "bump/file_fetchers/base"

module Bump
  module FileFetchers
    module Ruby
      class Bundler < Bump::FileFetchers::Base
        def self.required_files
          %w(Gemfile Gemfile.lock)
        end

        private

        def extra_files
          lockfile = ::Bundler::LockfileParser.new(gemfile_lock)
          path_specs = lockfile.specs.select do |spec|
            spec.source.instance_of?(::Bundler::Source::Path)
          end
          path_specs.map do |spec|
            dir, base = spec.source.path.split
            file = File.join(dir, base, "#{base}.gemspec")
            fetch_file_from_github(file)
          end
        end

        def gemfile_lock
          gemfile_lock = required_files.find do |file|
            file.name == "Gemfile.lock"
          end
          gemfile_lock.content
        end
      end
    end
  end
end
