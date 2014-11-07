FolderPath = "/Users/deity/programming/hcil_rails"
FilePath = 'app/admin/person.rb'

class GitController < ApplicationController
  def index
    repo = Gitlab::Git::Repository.new(FolderPath)
    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit:1000,
      path: FilePath
    })

    @blobs = commits.map { |c| Gitlab::Git::Blob.find(repo, c.id, FilePath) }.reverse
  end
end
