# frozen_string_literal: true
require "bump/file_fetchers/elixir/hex"
require_relative "../shared_examples_for_file_fetchers"

RSpec.describe Bump::FileFetchers::Elixir::Hex do
  it_behaves_like "a dependency file fetcher"
end
