# frozen_string_literal: true
require "bump/file_fetchers/base"

module Bump
  module FileFetchers
    module Cocoa
      class CocoaPods < Bump::FileFetchers::Base
        def self.required_files
          %w(Podfile Podfile.lock)
        end
      end
    end
  end
end
