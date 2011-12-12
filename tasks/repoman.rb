$LOAD_PATH.unshift(File.expand_path('lib'))

require 'chef/log' ; ::Log = Chef::Log
require 'gorillib/logger/log'

require 'json'
require 'chef/mash'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/hash/reverse_merge'
require 'gorillib/object/blank'
require 'gorillib/hash/compact'
require 'set'
require 'cluster_chef/dsl_object'
require 'rest-client'

def Log.dump(*args) self.debug([args.map(&:inspect), caller.first ].join("\t")) ;end 
Log.level = :info 
# Log.level = :debug ; RestClient.log = Log

module ClusterChef
  module Repoman

    class Collection < ClusterChef::DslObject
      has_keys(
        :container_dir,    # holds the bare/ and single/ versions of the repo
        :push_urlbase,     # base url for target repo names, eg git@github.com:infochimps-cookbooks
        # for managing github repos
        :github_api_urlbase,   # github API url base
        :github_org,           # github organization, eg 'infochimps-cookbooks'
        :github_team,          # github team to authorize for the repo
        :github_username,      # github username
        :github_token          # github token
        )

      def initialize(paths, hsh={}, &block)
        super(hsh, &block)
        defaults
        @repos = Mash.new
        paths.each do |path|
          repo = ClusterChef::Repoman::Repo.new(self, path)
          @repos[repo.name] = repo
        end
      end

      # repo object for each subtree under management
      def repo(repo_name)
        @repos[repo_name]
      end
      # names for each known repo
      def repo_names
        @repos.keys
      end

      def defaults
        @settings[:github_api_urlbase] ||= 'https://github.com/api/v2/json'
        @settings[:push_urlbase]  ||= "git@github.com:#{github_org}"
        set_github_credentials
      end

      def set_github_credentials
        return if github_username.present? && github_token.present?
        self.github_username( ENV['GITHUB_USERNAME'] || `git config --get github.user` )
        self.github_username.strip!
        self.github_token( ENV['GITHUB_TOKEN']    || `git config --get github.token` )
        self.github_token.strip!
        if github_username.blank? || github_token.blank?
          raise ("Please set your github username (got #{github_username}) and token (got #{github_token}): either as environment variables GITHUB_USERNAME and GITHUB_TOKEN, OR in your ~/.gitconfig like so:\n\n[github]\n    user  = mrflip\n    token = 8675309beefcafe123456abcadaba123\n")
        end
      end

      def github_api_post(url_path, hsh={}, &block)
        url_path = "#{github_api_urlbase}/#{url_path}"
        hsh      = hsh.merge(:login => github_username, :token => github_token)
        response = RestClient.post(url_path, hsh, &block)
        return JSON.parse(response.to_str)
      end

      def github_api_get(url_path, hsh={})
        url_path = "#{github_api_urlbase}/#{url_path}"
        Log.dump(url_path, hsh)
        hsh = hsh.merge(:login => github_username, :token => github_token)
        response = RestClient.get(url_path, hsh)
        return JSON.parse(response.to_str)
      end

      # convert to string, but mask the token
      def to_s()
        [ super.gsub(/(github_token"=>"....)[^"]+"/,'\1....."' )[0..-3],
          " repos=#{@repos.values.map(&:name).inspect}", "}>"
        ].join
      end

    end


    class Repo < ClusterChef::DslObject
      include ::Rake::Cloneable
      include ::Rake::DSL
      
      attr_reader :collection
      attr_reader :path
      has_keys(
        :name,           
        :github_public   # is the repo public or private?
        )

      def initialize(collection, path, hsh={}, &block)
        super(hsh)
        @collection = collection
        @path       = path
        name(File.basename(path))

        yield self if block_given?
        arg_names = [:name]
        missing = arg_names.select{|arg| self.send(arg).blank? }
        raise ArgumentError, "Please supply #{missing.join(', ')} in #{self}" unless missing.empty?

        define_bare_tasks        
      end

      def container
        REPOMAN_ROOT_DIR
      end

      # Actually set up the tasks
      def define_bare_tasks
        namespace('repo:bare') do
          @my_task = task "create_#{name}"
          task "create_#{name}" => bare_dir
          task "create_#{name}" => bare_repo_presence

          # holds the bare repo
          directory(bare_dir)
          # git init, only if needed
          file(bare_repo_presence) do
            ENV['GIT_DIR'] = bare_dir
            sh 'git init'
          end
        end
        task 'repo:bare' => "create_#{name}"
      end
      # Directory holding the bare repo
      def bare_dir()           File.join(container, 'bare', "#{name}.git") ; end
      # if this file is present the repo is assumed to exist
      def bare_repo_presence() File.join(bare_dir, 'HEAD') end

      def invoke
        task("repo:bare:create_#{name}").invoke
      end
      
      #
      # Github: Attributes
      #
      
      def github_repo_name
        "#{collection.github_org}/#{name}"
      end
      def github_repo_url
        "#{collection.push_urlbase}/#{github_repo_name}"
      end

      def public?
        (github_public.to_s != "false") && (github_public.to_s != '0')
      end

      #
      # Actions
      #

      # Hash of info about the repo on github
      def github_info
        collection.github_api_get("repos/show/#{github_repo_name}")
      end

      # Create the repo if it doesn't exist
      def github_create
        Log.debug("Creating #{name}")
        collection.github_api_post("repos/create",
          :name   => github_repo_name, :public => (public? ? '1' : '0') ) do |*args, &block|
          harmless(:create, 422, *args, &block)
        end
      end

      def github_update
        Log.debug("Updating #{name} metadata")
        collection.github_api_post("repos/show/#{github_repo_name}",
          :name   => github_repo_name,
          :values => {
            :homepage => "http://github.com/infochimps-labs/cluster_chef-homebase",
            :has_wiki   => "0",
            :has_issues => "0",
            :has_downloads => "1",
            :description => "#{name} chef cookbook - automatically installs and configures #{name}",
          })        
      end

      def github_add_teams
        Log.debug("Authorizing team #{collection.github_team} on #{name}")
        collection.github_api_post("teams/#{collection.github_team}/repositories",
          :name => github_repo_name)
      end

      def github_delete!
        response = collection.github_api_post("repos/delete/#{github_repo_name}") do |*args, &block|
          harmless(:delete, 404, *args, &block)
        end
        del_tok = response['delete_token']
        if   not del_tok
          Log.warn "No delete token, Skipping delete"
          {:skipping => true }
        elsif not ENV['REPOMAN_LOOK_IN_TRUNK']
          Log.warn "Not deleting repo #{name} at #{github_repo_url}. Set environment variable REPOMAN_LOOK_IN_TRUNK=true to actually delete"
          {:skipping => true }
        else
          Log.warn "Deleting repo #{name} at #{github_repo_url}"
          collection.github_api_post("repos/delete/#{github_repo_name}", :delete_token => del_tok)
        end
      end

      #
      # Helpers
      #

      def harmless(action, ok_codes, resp, req, result, &block)
        if Array(ok_codes).include?(resp.code)
          Log.debug("Github repo #{github_repo_name} doesn't need #{action} (#{resp.to_s}), skipping")
          resp
        else
          resp.return!(req, result, &block)
        end
      end

    end
  end
end
