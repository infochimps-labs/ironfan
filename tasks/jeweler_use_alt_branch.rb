
#
#
#

Jeweler::Commands::ReleaseToGit.class_eval do
  def run
    unless clean_staging_area?
      system "git status"
      raise "Unclean staging area! Be sure to commit or .gitignore everything first. See `git status` above."
    end

    repo.checkout($jeweler_push_from_branch || 'master')
    repo.push

    if release_not_tagged?
      output.puts "Tagging #{release_tag}"
      repo.add_tag(release_tag)

      output.puts "Pushing #{release_tag} to origin"
      repo.push('origin', release_tag)
    end
  end
end
