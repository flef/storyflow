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
    authorHashTable = {}
    author_num = 0

    blame_data = commits.reverse.each_with_index.map do |c, commit_i|
      
      blob = Gitlab::Git::Blob.find(repo, c.id, FilePath) 
      blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: c.id })
      
      commitHashTable[c.id] = commit_i

      unless authorHashTable[c.author_name]
        authorHashTable[c.author_name] = author_num
        author_num += 1
      end

      blame_content_array = blame.each_with_index.map do |b, blame_i|
        startLine = b[:final_start_line_number] - 1
        endLine  = startLine + b[:lines_in_hunk] - 1      

        #b
        { 
          content: blob.data.lines[startLine..endLine].each { |l| l.delete!("\n") },
          commit_number: commitHashTable[b[:orig_commit_id]],
          blame_id: "#{commit_i}_#{blame_i}",
          commit_id: b[:orig_commit_id][0..7],
          final_line: b[:final_start_line_number],
          orig_line: b[:orig_start_line_number],
          lines: b[:lines_in_hunk],
          author_number: authorHashTable[c.author_name]
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
      commit_hash[:id] = c.id[0..7]
      commit_hash[:gravatar] = hash.split(//).inject(0) {|z, x| z + x.to_i(10)}
      commit_hash[:authored_date] = commit_hash[:authored_date].utc.to_i*1000
      commit_hash[:committed_date] = commit_hash[:committed_date].utc.to_i*1000
      commit_hash
    end

    ###
    # compute percent of remaining code by author and commit
    ###
    total_lines = 0.0
    remainders_authors = {}
    remainders_commits = {}

    blame = Rugged::Blame.new(repo.rugged, FilePath, { newest_commit: commits.first.id })    
    blame.each.map do |b|
      total_lines += b[:lines_in_hunk]
    end

    blame.each.map do |b|
      remainders_commits[b[:final_commit_id]] ||= 0
      remainders_commits[b[:final_commit_id]] += b[:lines_in_hunk] / total_lines
      remainders_authors[b[:final_signature][:email]] ||= 0
      remainders_authors[b[:final_signature][:email]] += b[:lines_in_hunk] / total_lines      
    end
    ###
    ###

    author_data = authorHashTable

    history_data = { numberOfCommit: commits.length, history: history_commits}
    {blame_data: blame_data, author_data: author_data, history_data: history_data, remainders_data: {authors: remainders_authors, commits: remainders_commits}}    
  end

  def data
    respond_to do |format|
      format.html
      format.json { render :json => raw_data }
      format.xml { render :xml => raw_data }
    end
  end
end
