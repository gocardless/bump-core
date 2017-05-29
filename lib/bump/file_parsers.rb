# frozen_string_literal: true
require "bump/file_parsers/ruby/bundler"
require "bump/file_parsers/python/pip"
require "bump/file_parsers/java_script/yarn"
require "bump/file_parsers/elixir/hex"

module Bump
  module FileParsers
    def self.for_package_manager(package_manager)
      case package_manager
      when "bundler" then FileParsers::Ruby::Bundler
      when "yarn" then FileParsers::JavaScript::Yarn
      when "pip" then FileParsers::Python::Pip
      when "hex_elixir" then FileParsers::Elixir::Hex
      else raise "Unsupported package_manager #{package_manager}"
      end
    end
  end
end
