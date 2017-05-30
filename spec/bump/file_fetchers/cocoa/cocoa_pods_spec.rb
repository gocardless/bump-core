# frozen_string_literal: true
require "bump/file_fetchers/cocoa/cocoa_pods"
require_relative "../shared_examples_for_file_fetchers"

RSpec.describe Bump::FileFetchers::Cocoa::CocoaPods do
  it_behaves_like "a dependency file fetcher"
end
