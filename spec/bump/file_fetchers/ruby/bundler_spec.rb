# frozen_string_literal: true
require "bump/file_fetchers/ruby/bundler"
require_relative "../shared_examples_for_file_fetchers"

RSpec.describe Bump::FileFetchers::Ruby::Bundler do
  it_behaves_like "a dependency file fetcher"

  let(:repo) { Bump::Repo.new(name: "gocardless/bump", commit: nil) }
  let(:github_client) { Octokit::Client.new(access_token: "token") }
  let(:file_fetcher_instance) do
    described_class.new(repo: repo, github_client: github_client)
  end

  subject(:files) { file_fetcher_instance.files }
  let(:url) { "https://api.github.com/repos/#{repo.name}/contents/" }

  context "gemfile with path dependency" do
    before do
      stub_request(:get, url + "Gemfile").
        to_return(status: 200,
                  body: fixture(
                    "github", "gemfile_with_path_content.json"
                  ),
                  headers: { "content-type" => "application/json" })
      stub_request(:get, url + "Gemfile.lock").
        to_return(status: 200,
                  body: fixture(
                    "github", "gemfile_lock_with_path_content.json"
                  ),
                  headers: { "content-type" => "application/json" })

      stub_request(:get, url + "plugins/bump-core/bump-core.gemspec").
        to_return(status: 200,
                  body: fixture(
                    "github", "gemspec_content.json"
                  ),
                  headers: { "content-type" => "application/json" })
    end

    it "fetches gemspec from path dependency" do
      expect(files.map(&:name)).
        to include("plugins/bump-core/bump-core.gemspec")
    end
  end
end
