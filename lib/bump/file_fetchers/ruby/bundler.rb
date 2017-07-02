# frozen_string_literal: true
require "bump/file_fetchers/base"

module Bump
  module FileFetchers
    module Ruby
      class Bundler < Bump::FileFetchers::Base
        def self.required_files
          %w(Gemfile Gemfile.lock)
        end

        # We currently don't support path-based dependencies, so, we
        # remove them from the Gemfile entirely.
        #
        # We'll resolve the Gemfile without a line (it'll be removed)
        # from the file, which is not ideal but it'll at
        # least allow us to resolve what needs to update as opposed
        # to not resolving anything at all.
        def files
          super do |file_content|
            file_content.lines.reject do |line|
              line.include?("path")
            end.join
          end
        end
      end
    end
  end
end
