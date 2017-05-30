# frozen_string_literal: true
require "bump/file_fetchers/base"

module Bump
  module FileFetchers
    module Elixir
      class Hex < Bump::FileFetchers::Base
        def self.required_files
          %w(mix.exs mix.lock)
        end
      end
    end
  end
end
