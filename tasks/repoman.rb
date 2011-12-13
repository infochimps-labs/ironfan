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
require 'grit'

def Log.dump(*args) self.debug([args.map(&:inspect), caller.first ].join("\t")) ;end
Log.level = :info
Log.level = :debug ; RestClient.log = Log

module ClusterChef
  module Repoman

    class Collection < ClusterChef::DslObject
      include ::Rake::Cloneable
      include ::Rake::DSL
      attr_reader :repos
      has_keys(
        :container_dir,      # holds the bare/ and single/ versions of the repo
        :main_dir,         # the local checkout to mine
        :push_urlbase,       # base url for target repo names, eg git@github.com:infochimps-cookbooks
        :vendor,             # direectory within vendor/ to target inside homebase
        :github_api_urlbase, # github API url base
        :github_org,         # github organization, eg 'infochimps-cookbooks'
        :github_team,        # github team to authorize for the repo
        :github_username,    # github username
        :github_token        # github token
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

      def defaults
        @settings[:github_api_urlbase] ||= 'https://github.com/api/v2/json'
        @settings[:push_urlbase]  ||= "git@github.com:"
        set_github_credentials
      end

      #
      # Locations
      #

      # repo object for each subtree under management
      def repo(repo_name)
        @repos[repo_name]
      end
      # names for each known repo
      def repo_names
        @repos.keys
      end
      def each_repo
        @repos.values.each{|repo| yield(repo) }
      end

      def main_repo
        @main_repo ||= Grit::Repo.new(main_dir)
      end

      def in_main_tree
        raise "Repo dirty. Too terrified to move.\n#{filth}" unless clean?
        cd main_dir do
          sh("git", "checkout", "main")
          yield
        end
      end

      def subtree_add_all
        cd File.expand_path('~/ics/sysadmin/homebase') do
          each_repo do |repo|
            file("vendor/#{vendor}/#{repo.name}") do
              puts "#{repo.name} subtreeing"
              sh("git", "subtree", "add", "-P", "vendor/#{vendor}/#{repo.name}", File.join(repo.solo_dir, '.git'), "master")
            end
            file("cookbooks/#{repo.name}"){ symlink("../vendor/#{vendor}/#{repo.name}", "cookbooks") }
            task("add_subtree_#{repo.name}" => ["vendor/#{vendor}/#{repo.name}", "cookbooks/#{repo.name}"]).invoke
          end
        end
      end

      #
      # Github
      #

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

      def clean?
        st = main_repo.status
        st.changed.empty? && st.added.empty? && st.deleted.empty? && st.untracked.empty?
      end
      def filth
        st = main_repo.status
        [   "  changed   #{  st.changed.values.map(&:path).join(', ')}",
            "  added     #{    st.added.values.map(&:path).join(', ')}",
            "  deleted   #{  st.deleted.values.map(&:path).join(', ')}",
            "  untracked #{st.untracked.values.map(&:path).join(', ')}", ].join("\n")
      end
    end


    class Repo < ClusterChef::DslObject
      include ::Rake::Cloneable
      include ::Rake::DSL

      attr_reader :collection  # collection this belongs to
      attr_reader :path        # path within main repo
      attr_reader :shas        # shas for various incarnations
      has_keys(
        :name,
        :github_public   # is the repo public or private?
        )

      def initialize(collection, path, hsh={}, &block)
        super(hsh)
        @collection = collection
        @path       = path
        @shas       = {}
        name(File.basename(path))

        yield self if block_given?
        arg_names = [:name]
        missing = arg_names.select{|arg| self.send(arg).blank? }
        raise ArgumentError, "Please supply #{missing.join(', ')} in #{self}" unless missing.empty?
      end

      def container
        REPOMAN_ROOT_DIR
      end

      # Directory holding the main repo
      def main_dir()   collection.main_dir  end

      # Directory holding the solo repo
      def solo_dir()   File.join(container, 'solo', name)  end

      # if this file is present the repo is assumed to exist
      def solo_repo_presence() File.join(solo_dir, '.git', 'HEAD') end

      #
      # Repo splitting
      #

      # Extract git history from component's local path into its own branch in
      # this repo. For example, Repo.new(clxn, 'hadoop_cluster').git_split
      # creates a branch 'hadoop_cluster' with only the commits in the
      # cookbooks/hadoop_cluster file tree. If you +git checkout
      # hadoop_cluster+, you'll have only subdirectories named 'recipes',
      # 'templates', etc. -- it'the contents of the single target repo.
      def git_subtree_split
        shas[:sr_before] = git_main_branch.commit.to_s rescue nil
        Log.debug("Extracting subtree for #{name} from #{path} in #{main_dir}; was at #{shas[:sr_before] || '()'}")
        sh( "git-subtree", "split", "-P", path, "-b", branch_name ){|ok, status| Log.debug("status #{status}") }
        shas[:sr_after] = git_main_branch.commit.to_s rescue nil
        shas
      end

      def branch_name
        "br-#{name}"
      end

      def git_main_branch
        collection.main_repo.branches.detect{|branch| branch.name == branch_name }
      end

      #
      # Solo repo (non-bare local checkout of the repo)
      #

      def create_solo
        namespace('repo:solo') do
          task "create_#{name}" => File.dirname(solo_dir)
          task "create_#{name}" => solo_repo_presence
          #
          directory(File.dirname(solo_dir))
          file(solo_repo_presence){ git_clone_solo }
        end
        task 'repo:solo' => "repo:solo:create_#{name}"
        task("repo:solo:create_#{name}")
      end

      def git_clone_solo
        cd File.dirname(solo_dir) do
          sh('git', 'clone', github_repo_url)
        end
      end

      def pull_to_solo_from_main
        create_solo
        task "repo:solo:pull_to_#{name}_from_main" => "repo:solo:create_#{name}" do
          cd solo_dir do
            sh('git', 'pull', "#{main_dir}/.git", "#{branch_name}:master")
          end
        end
      end

      def push_from_solo_to_github
        create_solo
        task "repo:solo:push_from_#{name}_to_github" => "repo:solo:create_#{name}" do
          cd solo_dir do
            sh('git', 'push', github_repo_url, "master:master")
          end
        end
      end

      #
      # Github: Attributes
      #

      def github_repo_name
        "#{collection.github_org}/#{name}"
      end
      def github_repo_url
        "#{collection.push_urlbase}#{github_repo_name}.git"
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

      def github_sync
        info = {}
        info[:create] = github_create
        info[:auth  ] = github_add_teams
        info[:update] = github_update
        Log.info("synced #{name}")
        info
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
