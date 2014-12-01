class AuthorBlock
  constructor: (@author_name, @commit_data) ->
    #console.log @author_name, @commit_data

  getHTML: ->
    author_block = (html) =>
      "<div class='author_block'>
        <div class='author_info'>
          #{@author_name}: #{@commit_data.length} commits
        </div>
        #{html}
      </div>"

    commit_block = (commit_id, html) ->
      #"<div class='author_commit_block hidden'>#{html}</div>"
      "<div class='author_commit_block commit_#{commit_id}'>
      #{html}
      </div>"

    commits = @commit_data.map (commit) ->
      commit_block(commit.id.substr(0, 6), "#{commit.id.substr(0, 6)}: #{commit.message}")

    return author_block(commits.join(""))

$ ->
  window.controller = new Controller
