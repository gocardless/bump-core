# frozen_string_literal: true
require "octokit"
require "spec_helper"
require "bump/dependency"
require "bump/dependency_file"
require "bump/pull_request_creator"

RSpec.describe Bump::PullRequestCreator do
  subject(:creator) do
    described_class.new(
      repo_name: repo,
      branch_name: branch_name,
      github_client: github_client
    )
  end

  let(:repo) { "gocardless/bump" }
  let(:branch_name) { "bump/ruby/business-1.5.0" }
  let(:github_client) { Octokit::Client.new(access_token: "token") }

  let(:json_header) { { "Content-Type" => "application/json" } }
  let(:watched_repo_url) { "https://api.github.com/repos/#{repo}" }

  before do
    stub_request(:get, watched_repo_url).
      to_return(status: 200,
                body: fixture("github", "bump_repo.json"),
                headers: json_header)
    stub_request(:get, "#{watched_repo_url}/branches/#{branch_name}").
      to_return(status: 200,
                body: fixture("github", "branch.json"),
                headers: json_header)
    stub_request(:post, "#{watched_repo_url}/pulls").
      to_return(status: 200,
                body: fixture("github", "create_pr.json"),
                headers: json_header)
  end

  describe "#create" do
    it "creates a PR with the right details" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{watched_repo_url}/pulls").
        with(
          body: {
            base: "master",
            head: "bump/ruby/business-1.5.0",
            title: "Bump business to 1.5.0",
            body: "Bumps [business](https://github.com/gocardless/business) "\
                  "from 1.4.0 to 1.5.0.\n- [Release notes]"\
                  "(https://github.com/gocardless/business/releases/tag"\
                  "/v1.5.0)\n- [Changelog]"\
                  "(https://github.com/gocardless/business/blob/master"\
                  "/CHANGELOG.md)\n- [Commits]"\
                  "(https://github.com/gocardless/business/"\
                  "compare/v1.4.0...v1.5.0)"
          }
        )
    end

    it "returns details of the created pull request" do
      expect(creator.create.title).to eq("new-feature")
      expect(creator.create.number).to eq(1347)
    end

    context "with a custom footer" do
      subject(:creator) do
        described_class.new(
          repo_name: repo,
          branch_name: branch_name,
          github_client: github_client,
          pr_message_footer: "Example text"
        )
      end

      it "includes the custom text in the PR message" do
        creator.create

        expect(WebMock).
          to have_requested(:post, "#{watched_repo_url}/pulls").
          with(
            body: {
              base: "master",
              head: "bump/ruby/business-1.5.0",
              title: "Bump business to 1.5.0",
              body: /\n\nExample text/
            }
          )
      end
    end
  end
end
