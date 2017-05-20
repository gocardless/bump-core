# frozen_string_literal: true
require "octokit"
require "spec_helper"
require "bump/dependency"
require "bump/dependency_file"
require "bump/dependency_file_pusher"

RSpec.describe Bump::DependencyFilePusher do
  subject(:creator) do
    Bump::DependencyFilePusher.new(repo: repo,
                                   base_commit: base_commit,
                                   dependency: dependency,
                                   files: files,
                                   github_client: github_client,
                                   target_branch: target_branch)
  end

  let(:dependency) do
    Bump::Dependency.new(name: "business",
                         version: "1.5.0",
                         previous_version: "1.4.0",
                         language: "ruby")
  end
  let(:repo) { "gocardless/bump" }
  let(:files) { [gemfile, gemfile_lock] }
  let(:base_commit) { "basecommitsha" }
  let(:github_client) { Octokit::Client.new(access_token: "token") }
  let(:target_branch) { nil }

  let(:gemfile) do
    Bump::DependencyFile.new(
      name: "Gemfile",
      content: fixture("ruby", "gemfiles", "Gemfile")
    )
  end
  let(:gemfile_lock) do
    Bump::DependencyFile.new(
      name: "Gemfile.lock",
      content: fixture("ruby", "lockfiles", "Gemfile.lock")
    )
  end

  let(:json_header) { { "Content-Type" => "application/json" } }
  let(:repo_url) { "https://api.github.com/repos/#{repo}" }
  let(:business_repo_url) { "https://api.github.com/repos/gocardless/business" }
  let(:branch_name) { "bump/ruby/business-1.5.0" }

  before do
    stub_request(:get, repo_url).
      to_return(status: 200,
                body: fixture("github", "bump_repo.json"),
                headers: json_header)
    stub_request(:get, "#{repo_url}/git/refs/heads/#{branch_name}").
      to_return(status: 404,
                body: fixture("github", "not_found.json"),
                headers: json_header)
    stub_request(:post, "#{repo_url}/git/trees").
      to_return(status: 200,
                body: fixture("github", "create_tree.json"),
                headers: json_header)
    stub_request(:post, "#{repo_url}/git/commits").
      to_return(status: 200,
                body: fixture("github", "create_commit.json"),
                headers: json_header)
    stub_request(:post, "#{repo_url}/git/refs").
      to_return(status: 200,
                body: fixture("github", "create_ref.json"),
                headers: json_header)

    stub_request(:get, business_repo_url).
      to_return(status: 200,
                body: fixture("github", "business_repo.json"),
                headers: json_header)
    stub_request(:get, "#{business_repo_url}/contents/").
      to_return(status: 200,
                body: fixture("github", "business_files.json"),
                headers: json_header)
    stub_request(:get, "#{business_repo_url}/tags").
      to_return(status: 200,
                body: fixture("github", "business_tags.json"),
                headers: json_header)
    stub_request(:get, "#{business_repo_url}/releases").
      to_return(status: 200,
                body: fixture("github", "business_releases.json"),
                headers: json_header)
    stub_request(:get, "https://rubygems.org/api/v1/gems/business.json").
      to_return(status: 200, body: fixture("rubygems_response.json"))
  end

  describe "#create" do
    it "pushes a commit to GitHub" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{repo_url}/git/trees").
        with(body: {
               base_tree: "basecommitsha",
               tree: [
                 {
                   path: "Gemfile",
                   mode: "100644",
                   type: "blob",
                   content: fixture("ruby", "gemfiles", "Gemfile")
                 },
                 {
                   path: "Gemfile.lock",
                   mode: "100644",
                   type: "blob",
                   content: fixture("ruby", "lockfiles", "Gemfile.lock")
                 }
               ]
             })

      expect(WebMock).
        to have_requested(:post, "#{repo_url}/git/commits")
    end

    it "has the right commit message" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{repo_url}/git/commits").
        with(body: {
               parents: ["basecommitsha"],
               tree: "cd8274d15fa3ae2ab983129fb037999f264ba9a7",
               message: /Bump business to 1\.5\.0\n\nBumps \[business\]/
             })
    end

    it "creates a branch for that commit" do
      creator.create

      expect(WebMock).
        to have_requested(:post, "#{repo_url}/git/refs").
        with(body: {
               ref: "refs/heads/bump/ruby/business-1.5.0",
               sha: "7638417db6d59f3c431d3e1f261cc637155684cd"
             })
    end

    it "returns details of the created branch" do
      expect(creator.create.ref).to eq("refs/heads/bump/ruby/business-1.5.0")
    end

    context "when a branch for this update already exists" do
      before do
        stub_request(:get, "#{repo_url}/git/refs/heads/#{branch_name}").
          to_return(status: 200,
                    body: fixture("github", "check_ref.json"),
                    headers: json_header)
      end

      specify { expect { creator.create }.to_not raise_error }

      it "doesn't push changes to the branch" do
        creator.create

        expect(WebMock).
          to_not have_requested(:post, "#{repo_url}/git/trees")
      end
    end

    context "when there's a race to create the new branch, and we lose" do
      before do
        stub_request(:post, "#{repo_url}/git/refs").
          to_return(status: 422,
                    body: fixture("github", "create_ref_error.json"),
                    headers: json_header)
      end

      specify { expect(creator.create).to be_nil }
    end

    context "with a directory specified" do
      let(:gemfile) do
        Bump::DependencyFile.new(
          name: "Gemfile",
          content: fixture("ruby", "gemfiles", "Gemfile"),
          directory: "directory"
        )
      end
      let(:gemfile_lock) do
        Bump::DependencyFile.new(
          name: "Gemfile.lock",
          content: fixture("ruby", "lockfiles", "Gemfile.lock"),
          directory: "directory"
        )
      end
      let(:branch_name) { "bump/ruby/directory/business-1.5.0" }

      it "includes the directory in the path of the files pushed to GitHub" do
        creator.create

        expect(WebMock).
          to have_requested(:post, "#{repo_url}/git/trees").
          with(body: {
                 base_tree: "basecommitsha",
                 tree: [
                   {
                     path: "directory/Gemfile",
                     mode: "100644",
                     type: "blob",
                     content: fixture("ruby", "gemfiles", "Gemfile")
                   },
                   {
                     path: "directory/Gemfile.lock",
                     mode: "100644",
                     type: "blob",
                     content: fixture("ruby", "lockfiles", "Gemfile.lock")
                   }
                 ]
               })
      end

      it "includes the directory in the commit message" do
        creator.create

        expect(WebMock).
          to have_requested(:post, "#{repo_url}/git/commits").
          with(body: {
                 parents: ["basecommitsha"],
                 tree: "cd8274d15fa3ae2ab983129fb037999f264ba9a7",
                 message: %r{Bump business to 1\.5\.0\ in /directory}
               })
      end

      it "includes the directory in the branch name" do
        creator.create

        expect(WebMock).
          to have_requested(:post, "#{repo_url}/git/refs").
          with(body: {
                 ref: "refs/heads/bump/ruby/directory/business-1.5.0",
                 sha: "7638417db6d59f3c431d3e1f261cc637155684cd"
               })
      end
    end

    context "with a target branch specified" do
      let(:target_branch) { branch_name }
      before do
        stub_request(:get, "#{repo_url}/git/refs/heads/#{branch_name}").
          to_return(status: 200,
                    body: fixture("github", "check_ref.json"),
                    headers: json_header)
        stub_request(:patch, "#{repo_url}/git/refs/heads/#{target_branch}").
          to_return(status: 200,
                    body: fixture("github", "update_ref.json"),
                    headers: json_header)
      end

      it "updates the branch to point to the new commit" do
        creator.create

        expect(WebMock).
          to have_requested(
            :patch, "#{repo_url}/git/refs/heads/#{branch_name}"
          ).with(
            body: {
              sha: "7638417db6d59f3c431d3e1f261cc637155684cd",
              force: true
            }
          )
      end

      it "returns details of the updated branch" do
        expect(creator.create.object.sha).
          to eq("1e2d2afe8320998baecdfe127a49dca9a6650e07")
      end

      context "when the target branch doesn't exists" do
        before do
          stub_request(:get, "#{repo_url}/git/refs/heads/#{branch_name}").
            to_return(status: 404,
                      body: fixture("github", "not_found.json"),
                      headers: json_header)
        end

        specify { expect { creator.create }.to raise_error(/Branch not found/) }
      end
    end
  end
end
