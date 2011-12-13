
#
# Jeweler has hardcoded the 'master' branch as where to push from.
# We hardcode it right back in.
#

module Jeweler::Commands

  PUSH_FROM_BRANCH = 'version_3' unless defined?(PUSH_FROM_BRANCH)

  ReleaseToGit.class_eval do
    def run
      branch = PUSH_FROM_BRANCH
      remote = 'origin'

      unless clean_staging_area?
        system "git status"
        raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
      end

      repo.checkout(branch)
      repo.push(remote, branch)

      if release_not_tagged?
        output.puts "Tagging #{release_tag}"
        repo.add_tag(release_tag)

        output.puts "Pushing #{release_tag} to origin"
        repo.push('origin', release_tag)
      end
    end
  end

  ReleaseGemspec.class_eval do
    def run
      branch = PUSH_FROM_BRANCH
      remote = 'origin'

      unless clean_staging_area?
        system "git status"
        raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
      end

      repo.checkout(branch)

      regenerate_gemspec!
      commit_gemspec! if gemspec_changed?

      output.puts "Pushing #{branch} to origin"
      repo.push(remote, branch)
    end
  end
end
