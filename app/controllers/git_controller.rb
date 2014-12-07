FolderPath = "."
FilePath = 'app/controllers/git_controller.rb'

#FilePath = 'app/assets/javascripts/history_flow.coffee'

#FolderPath = "/Users/deity/jquery.transit"
#FilePath = 'jquery.transit.js'

#FolderPath= "/Users/deity/2048/"
#FilePath = "js/game_manager.js"

class GitController < ApplicationController

  def sumDigits(num, base = 10)
    num.to_s(base).split(//).inject(0) {|z, x| z + x.to_i(base)}
  end


  def raw_data    
    repo = Gitlab::Git::Repository.new(FolderPath)
    commits = Gitlab::Git::Commit.where({
      repo: repo,
      ref: 'master',
      limit: 1000,
      path: FilePath
    })

    commitHashTable = {}
    links = {}
    previousBlames = {}


    blame_data = commits.reverse.each_with_index.map do |c, commit_i|
      links[commits.length - commit_i - 1] = []
      
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })

      commitHashTable[c.id] = commit_i
      
      blame.each_with_index do |b, blame_i|
        blameOrigCommitID = b[:final_commit_id]
        unless previousBlames[blameOrigCommitID].nil?
          previousBlames[blameOrigCommitID].each do |prevB|
            if (b[:orig_start_line_number] == prevB[:final_start_line_number] || (( b[:orig_start_line_number] - prevB[:final_start_line_number])).abs < prevB[:lines_in_hunk])
              #startLine = b[:final_start_line_number] - 1
              #endLine  = startLine + b[:lines_in_hunk] - 1   
              link = {}              
              link[:srcX] = commits.length - commit_i - 1
              link[:dstX] = commits.length - commit_i
              link[:srcY] = b[:final_start_line_number]
              link[:dstY] = b[:orig_start_line_number]
              link[:dY]   = b[:lines_in_hunk]
              link[:info] = "FROM_C#{link[:srcX]}_B#{blame_i}_TO_C#{link[:dstX]}_B#{prevB[:index]}"
              links[commits.length - commit_i - 1] << link #[previousBlames, link, b, blob.data.lines[startLine..endLine].each { |l| }] #link
            end
          end
        end
      end
      previousBlames = {}

      blame_content_array = blame.each_with_index.map do |b, blame_i|

        blameOrigCommitID = b[:orig_commit_id]
        b[:index] = blame_i
        previousBlames[blameOrigCommitID] = previousBlames[blameOrigCommitID] || []
        previousBlames[blameOrigCommitID] << b 

        startLine = b[:final_start_line_number] - 1
        endLine  = startLine + b[:lines_in_hunk] - 1

        #b
        { 
          content: blob.data.lines[startLine..endLine].each { |l| },
          commit_number: commitHashTable[b[:orig_commit_id]],
          blame_id: "#{commit_i}_#{blame_i}",
          commit_id: b[:orig_commit_id][0..7],
          final_line: b[:final_start_line_number],
          orig_line: b[:orig_start_line_number],
          lines: b[:lines_in_hunk]
        }
      end

      {commit_id: c.id[0..7], 
       blame_content_array: blame_content_array}
    end

    blame_data = blame_data.reverse

    # compute md5 of mail for gravatar
    history_commits = commits.map do |c|
      md5 = Digest::MD5.new
      md5 << c.author_email
      hash = md5.hexdigest
      hash.gsub! '\w', ''
      commit_hash = c.to_hash
      commit_hash[:gravatar] = hash.split(//).inject(0) {|z, x| z + x.to_i(10)}
      commit_hash[:authored_date] = commit_hash[:authored_date].utc.to_i*1000
      commit_hash[:committed_date] = commit_hash[:committed_date].utc.to_i*1000
      commit_hash
    end

    author_data = commits.group_by { |c| c.author_name }
    history_data = { numberOfCommit: commits.length, history: history_commits}
    {blame_data: blame_data, link_data: links, history_data: history_data}
  
    #commits.reverse.each_with_index do |c, cIndex|
      #blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      #blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      #table[cIndex] = {}
      #linesInHunk = {}
      
      #blame.each_with_index do |b, bIndex|
        #table[cIndex][b[:final_commit_id][0..7]] ||= Array.new 
        #table[cIndex][b[:final_commit_id][0..7]] << [nodeID, b]

        #b_lines = b[:lines_in_hunk]
        #startLine = b[:final_start_line_number] - 1
        #endLine  = startLine + b[:lines_in_hunk] - 1      
        
        #node << {
          #x: cIndex,
          #row: bIndex,
          #value: b_lines,
          #content: blob.data.lines[startLine..endLine].join("\n"), 
          #author: "c_#{cIndex}_b_#{bIndex}:#{b_lines}",
          #commit: b[:final_commit_id][0..7], 
          #name: "c_#{cIndex}_b_#{bIndex}",
        #}

        #linesInHunk[nodeID] = b_lines
        #nodeID += 1
      #end

      #table[cIndex].each do |commitID, aLink|
        #aLink.each do |destination|
          #if commitID != c.id[0..7]
              #table[cIndex-1][commitID].each do |source|
                #if (destination.last[:final_start_line_number] - source.last[:orig_start_line_number]).abs < source.last[:lines_in_hunk]
                  #link << {
                    #source: source.first,
                    #target: destination.first,
                    #source_line: destination.last[:orig_start_line_number] - 1, 
                    #target_line: destination.last[:final_start_line_number] - 1,
                    #value: destination.last[:lines_in_hunk]
                  #}
                  ##, :debug => [source.last, destination.last]}
                #end
              #end
          #end
        #end
      #end

    #prevCommit = c.id[0..7]
    #end
      
    #return {:nodes => node, :links => link}
    #return {:nodes => node}
  end

  def data
    respond_to do |format|
      format.html
      format.json { render :json => raw_data }
      format.xml { render :xml => raw_data }
    end
  end
end
