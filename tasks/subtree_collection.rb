$LOAD_PATH.unshift(File.expand_path('../lib', FILE.dirname(__FILE__)))
require 'gorillib/logger/log'
require 'json'
require 'cluster_chef/dsl_object'
require 'rest-client' ; RestClient.log = Log

module ClusterChef
  module Subtree

    class Collection < ClusterChef::DslObject
      # repo objects for each subtree under management
      attr_reader :repos
      has_keys(
        :container_dir,    # holds the bare/ and single/ versions of the repo
        :push_urlbase,     # base url for target repo names, eg git@github.com:infochimps-cookbooks
        # for managing github repos
        :gh_api_urlbase,   # github API url base
        :gh_username,      # github API username
        :gh_token          # github API token
        )

      def initialize(paths, setting={}, &block)
        super(settings, &block)
        defaults
        self.repos = paths.map do |path|
          ClusterChef::Subtree::Repo.new(self, path)
        end
      end

      def defaults
        @settings[:gh_api]        ||= 'https://github.com/api/v2/json'
        @settings[:push_url_base] ||= 'git@github.com:infochimps-cookbooks'
        set_github_credentials
      end

      def set_github_credentials
        return if gh_username.present? && gh_token.present?
        self.gh_username( ENV['GITHUB_USERNAME'] || `git config --get github.user` )
        self.gh_username.strip!
        self.gh_username( ENV['GITHUB_TOKEN']    || `git config --get github.token` )
        self.gh_username.strip!
        if gh_username.blank? || gh_token.blank?
          raise ("Please set your github username and token: either as environment variables GITHUB_USERNAME and GITHUB_TOKEN, OR in your ~/.gitconfig like so:\n\n[github]\n      user = mrflip\n token           = 8675309beefcafe123456abcadaba123\n")
        end
      end

      def github_api_post(url_path, hsh, &block)
        url_path = "#{gh_api_urlbase}/#{url_path}"
        hsh      = hsh.merge(:login => gh_username, :token => gh_token)
        response = RestClient.post(url_path, hsh, &block)
        return JSON.parse(response.to_str)
      end

      def github_api_get(url_path, hsh)
        hsh = hsh.merge(:login => gh_username, :token => gh_token)
        response = RestClient.get(url_path, hsh)
        return JSON.parse(response.to_str)
      end

    end


    class Repo < ClusterChef::DslObject
      attr_reader :collection
      attr_reader :path
      has_keys :name

      def initialize(collection, path)
        self.collection = collection
        self.path       = path
        name(File.basename(path))
      end

      # def github_delete!
      #   response = collection.github_api_post("repos/delete/#{collection.gh_org}/#{name}")
      #   puts response
      #   del_tok = response
      #   response = collection.github_api_post("repos/delete/#{collection.gh_org}/#{name}", :delete_token => del_tok)
      # end

      def github_show
        Log.info collection.github_api_get("repos/show/#{collection.gh_org}/#{name}")
      end

    end
  end
end
