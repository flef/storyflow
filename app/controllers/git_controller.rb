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

  def data
  end

  def rawdata
    repo = Gitlab::Git::Repository.new(FolderPath)
    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit:1000,
      path: FilePath
    })

    table = Hash.new
    node = Array.new
    link = Array.new

    nodeID = 0
    prevCommit = nil
  
    commits.reverse.each_with_index do |c, cIndex|
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      table[cIndex] = Hash.new
      linesInHunk = Hash.new
      
      blame.each_with_index do |b, bIndex|
        if table[cIndex][b[:final_commit_id][0..7]] == nil
          table[cIndex][b[:final_commit_id][0..7]] = Array.new 
        end

        table[cIndex][b[:final_commit_id][0..7]]  << nodeID 
  
        node << {:author => b[:final_signature][:name], :commit => b[:final_commit_id][0..7], :name   => "c_" + cIndex.to_s + "_b_" + bIndex.to_s }
        linesInHunk[nodeID] = b[:lines_in_hunk]

        nodeID += 1
      end

      table[cIndex].each do |commitID, aLink|
        aLink.each do |destination|
          if commitID != c.id[0..7]
              table[cIndex-1][commitID].each do |source|
                link << {:source => destination, :target => source, :value => linesInHunk[destination] * 50 }
              end
           elsif prevCommit != nil
              link << {:source => destination, :target => table[cIndex-1][prevCommit].first, :value => 1 }
          end
        end
      end

    prevCommit = c.id[0..7]
    end
      
    @infos = {:nodes => node, :links => link}

    respond_to do |format|
      format.json { render :json => @infos }
      format.xml { render :xml => @infos }
    end
  end
end
