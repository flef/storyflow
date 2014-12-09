FolderPath = "."
#FilePath = 'app/controllers/git_controller.rb'

FilePath = 'app/assets/javascripts/sidebar.coffee'

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
    followingBlames = {}


  commits.reverse.each_with_index do |c, commit_i|
      links[commits.length - commit_i - 1] = []
      logger.info c.committed_date.inspect
     
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })

      logger.info "Commit #{commit_i} :".inspect

      blame.each_with_index do |b, blame_i|
        logger.info "Blame #{blame_i} :".inspect
        blameOrigCommitID = b[:final_commit_id]
        if followingBlames[blameOrigCommitID]
          followingBlames[blameOrigCommitID].each do |followB|
            link = {}              
            link[:src] = "#{commit_i}_#{blame_i}"
            link[:dst] = followB[:id]
            link[:lines_number] = b[:lines_in_hunk]
            link[:start_line_number] = (followB[:start_line_number] - b[:orig_start_line_number]).abs
            
            if b[:orig_start_line_number] == followB[:start_line_number] ||
              followB[:lines_in_hunk] - b[:final_start_line_number] >= followB[:start_line_number]
              
              link[:info] = link.inspect
              links[commits.length - commit_i - 1] << link
              logger.info link.inspect
            end
          end
        end
      end

      logger.info "Recording previous blame on #{commit_i} :".inspect
      followingBlames = {}
      blame.each_with_index do |b, blame_i|
        blameOrigCommitID = b[:final_commit_id]
#        if blameOrigCommitID != c.id
          logger.info "Record blame #{blame_i} (commit #{commit_i})".inspect
          followingBlames[blameOrigCommitID] = followingBlames[blameOrigCommitID] || []
          followingBlames[blameOrigCommitID] << {id: "#{commit_i}_#{blame_i}",
                                                  lines_in_hunk: b[:lines_in_hunk], 
                                                  start_line_number: b[:final_start_line_number] 
                                                }
#        end 
      end
    end


    blame_data = commits.reverse.each_with_index.map do |c, commit_i|
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })

      commitHashTable[c.id] = commit_i

      blame_content_array = blame.each_with_index.map do |b, blame_i|

        blameOrigCommitID = b[:orig_commit_id]
        b[:index] = blame_i
        previousBlames[blameOrigCommitID] = previousBlames[blameOrigCommitID] || []
        previousBlames[blameOrigCommitID] << b 

        startLine = b[:final_start_line_number] - 1
        endLine  = startLine + b[:lines_in_hunk] - 1

        #b
        { 
          content: blob.data.lines[startLine..endLine].each_with_index.map { |l, i| "#{i+startLine}.(#{i}) #{l}" },
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
  end

  def data
    respond_to do |format|
      format.html
      format.json { render :json => raw_data }
      format.xml { render :xml => raw_data }
    end
  end
end
