module ClusterChef
  module Repoman
    class Repo < ClusterChef::DslObject

      #
      # Bare Repo
      #

      # Directory holding the bare repo
      def bare_dir()           File.join(container, 'bare', "#{name}.git") ; end
      # if this file is present the repo is assumed to exist
      def bare_repo_presence() File.join(bare_dir, 'HEAD') end

      # Executes rake tasks to create a bare repo
      def create_bare
        namespace('repo:bare') do
          task "create_#{name}" => bare_dir
          task "create_#{name}" => bare_repo_presence
          #
          directory(bare_dir)
          file(bare_repo_presence){ git_init_bare }
        end
        task "repo:bare" => "repo:bare:create_#{name}"
        task("repo:bare:create_#{name}")
      end

      def push_to_bare_from_main
        create_bare
        task "repo:bare:push_main_to_bare_#{name}" => "repo:bare:create_#{name}" do
          sh('git', 'push', bare_dir, "#{name}:master")
        end
      end

      def pull_to_solo_from_bare
        create_solo
        task "repo:solo:pull_to_#{name}_from_bare" => "repo:solo:create_#{name}" do
          cd solo_dir do
            sh('git', 'pull', bare_dir, "master:master")
          end
        end
      end

      def push_from_solo_to_github
        pull_to_solo_from_bare
        task "repo:solo:push_to_github_from_#{name}" => "repo:solo:pull_to_#{name}_from_bare" do
          cd solo_dir do
            sh('git', 'push', github_repo_url, "master:master")
          end
        end
      end

      def git_init_bare
        Log.debug("Creating bare repo #{bare_dir}")
        Grit::Repo.init_bare(bare_dir)
      end

      #
      # Git remote setup
      #

      def remote_name
        "gh-#{name}"
      end

      def git_remote
        remote_obj  = collection.main_repo.remotes.detect{|rem| rem.name == "#{remote_name}/master" }
        return remote_obj if remote_obj
        sh("git", "remote", "add", remote_name, github_repo_url){|ok, status| Log.debug( status ) }
        git_fetch
        collection.main_repo.remotes.detect{|rem| rem.name == remote_name }
      end

      def git_fetch
        sh("git", "fetch", remote_name)
      end

    end
  end
end


  # namespace :bare do
  #   desc 'repo mgmt: Create given bare repo'
  #   task :create, [:repo_name] do |rt, args|
  #     repoman, repo = get_repo(args.repo_name)
  #     repo.create_bare.invoke
  #   end
  # end
  #
  # desc 'repo mgmt: Create all bare repos'
  # task :bare do |rt, args|
  #   check_args(rt, args)
  #   repoman = get_repoman
  #   repoman.each_repo do |repo|
  #     repo.create_bare.invoke
  #   end
  # end
