class CommitBlock
  constructor: (@blame_data) ->
    #console.log @blame_data
  
  getHTML: ->
    commit_block = (html) ->
      "<div class='blame_commit_block'>#{html}</div>"

    blame_block = (commit_id, html) ->
      "<div class='blame_block commit_#{commit_id}' 
        style='background-color: ##{commit_id.substr(0, 6)}'>
        #{html}
      </div>"

    code_block = (code) ->
      "<div class='code_block'><pre>#{code}</pre></div>"

    blames = @blame_data.map (commit) ->
      codes = commit.content.map (line) ->
        code_block(line)

      blame_block(commit.final_commit_id, codes.join(""))

    return commit_block(blames.join(""))

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
      #</div>"

    commits = @commit_data.map (commit) ->
      commit_block(commit.id.substr(0, 6), "#{commit.id.substr(0, 6)}: #{commit.message}")

    return author_block(commits.join(""))

class Controller
  commit_blocks: []
  author_blocks: []

  make_smaller: ->
    window_size = $("#chartContainer").width()
    chart_size = $("#chart")[0].scrollWidth

    $(".code_block > pre").css("visibility", "hidden")
    $("#chart").transit({scale: window_size / chart_size})

  make_larger: ->
    $(".code_block > pre").css("visibility", "")
    $("#chart").transit({scale: 1})

  constructor: ->
    d3.json 'http://localhost:3000/data.json', (data) =>
      #console.log data
      
      for blame in data.blame_data
        @commit_blocks.push(new CommitBlock(blame))

      for author, commits of data.author_data
        @author_blocks.push(new AuthorBlock(author, commits))

      @putHTML()
      #@make_smaller()


  putHTML: ->
    @commit_blocks.forEach (c) ->
      $("#chart").append(c.getHTML())

    @author_blocks.forEach (a) ->
      $("#sidebar").append(a.getHTML())

$ ->
  window.controller = new Controller
