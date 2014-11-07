FolderPath = "/Users/deity/programming/graphics_hw"
FilePath = 'Animation/Animation/main.cpp'

class GitController < ApplicationController
  def index
    repo = Gitlab::Git::Repository.new(FolderPath)
    @blob = Gitlab::Git::Blob.find(repo, 'master', FilePath)
    logger.info @blob.inspect

    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit:1000,
      path: 'Animation/Animation/main.cpp'
    }).find_all { |c| Gitlab::Git::Blob.find(repo, c.id, FilePath) }

    @blobs = commits.map { |c| Gitlab::Git::Blob.find(repo, c.id, FilePath) }.reverse


  end
end
