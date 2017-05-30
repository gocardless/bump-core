# frozen_string_literal: true
require "bump/file_fetchers/ruby/bundler"
require "bump/file_fetchers/python/pip"
require "bump/file_fetchers/java_script/yarn"
require "bump/file_fetchers/cocoa/cocoa_pods"

module Bump
  module FileFetchers
    def self.for_package_manager(package_manager)
      case package_manager
      when "bundler" then FileFetchers::Ruby::Bundler
      when "yarn" then FileFetchers::JavaScript::Yarn
      when "pip" then FileFetchers::Python::Pip
      when "cocoapods" then FileFetchers::Cocoa::CocoaPods
      else raise "Unsupported package_manager #{package_manager}"
      end
    end
  end
end
