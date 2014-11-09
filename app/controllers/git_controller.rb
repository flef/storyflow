#FolderPath = "/Users/deity/programming/hcil_rails"
#FilePath = 'app/admin/person.rb'
FolderPath = "."
FilePath = 'app/controllers/git_controller.rb'

class GitController < ApplicationController
  def index
    repo = Gitlab::Git::Repository.new(FolderPath)
    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit:1000,
      path: FilePath
    })

    @data = commits.map do |c|
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      #blame = Gitlab::Git::Blame.new(repo, c.id, FilePath).instance_variable_get :@blame
      [c, blob, blame]
    end.reverse

  end
end
