#FolderPath = "/Users/deity/programming/hcil_rails"
#FilePath = 'app/admin/person.rb'
FolderPath = "."
FilePath = 'app/views/git/index.html.erb'

class GitController < ApplicationController
  #def index
    #repo = Gitlab::Git::Repository.new(FolderPath)
    #commits = Gitlab::Git::Commit.where({
      #repo: repo,
      #ref: 'master',
      #limit:1000,
      #path: FilePath
    #})

    #@data = commits.map do |c|
      #blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      #blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      ##blame = Gitlab::Git::Blame.new(repo, c.id, FilePath).instance_variable_get :@blame
      #[c, blob, blame]
    #end.reverse

  #end

  def raw_data
    repo = Gitlab::Git::Repository.new(FolderPath)
    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit:1000,
      path: FilePath
    })

    table = {}
    node = []
    link = []

    nodeID = 0
    prevCommit = nil
  
    commits.reverse.each_with_index do |c, cIndex|
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      table[cIndex] = {}
      linesInHunk = {}
      
      blame.each_with_index do |b, bIndex|
        table[cIndex][b[:final_commit_id][0..7]] ||= Array.new 
        table[cIndex][b[:final_commit_id][0..7]] << [nodeID, b]

        b_lines = b[:lines_in_hunk]
        startLine = b[:final_start_line_number] - 1
        endLine  = startLine + b[:lines_in_hunk] - 1      
        
        node << {
          x: cIndex,
          row: bIndex,
          value: b_lines,
          content: blob.data.lines[startLine..endLine].join("\n"), 
          author: "c_#{cIndex}_b_#{bIndex}:#{b_lines}",
          commit: b[:final_commit_id][0..7], 
          name: "c_#{cIndex}_b_#{bIndex}",
        }

        linesInHunk[nodeID] = b_lines
        nodeID += 1
      end

      table[cIndex].each do |commitID, aLink|
        aLink.each do |destination|
          if commitID != c.id[0..7]
              table[cIndex-1][commitID].each do |source|
                if (destination.last[:final_start_line_number] - source.last[:orig_start_line_number]).abs < source.last[:lines_in_hunk]
                  link << {
                    source: source.first,
                    target: destination.first,
                    source_line: destination.last[:orig_start_line_number] - 1, 
                    target_line: destination.last[:final_start_line_number] - 1,
                    value: destination.last[:lines_in_hunk]
                  }
                  #, :debug => [source.last, destination.last]}
                end
              end
          end
        end
      end

    prevCommit = c.id[0..7]
    end
      
    return {:nodes => node, :links => link}
  end

  def data
    respond_to do |format|
      format.html
      format.json { render :json => raw_data }
      format.xml { render :xml => raw_data }
    end
  end
end
