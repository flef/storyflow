class CommitBlock
  constructor: (@blame_data) ->
  
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
    console.log @author_name, @commit_data

  getHTML: ->
    author_block = (html) =>
      "<div class='author_block'>
        <div class='author_info'>
          #{@author_name}: #{@commit_data.length} commits
        </div>
        #{html}
      </div>"

    commit_block = (html) ->
      "<div class='author_commit_block hidden'>#{html}</div>"

    commits = @commit_data.map (commit) ->
      commit_block("#{commit.id.substr(0, 6)}: #{commit.message}")

    return author_block(commits.join(""))

class Controller
  commit_blocks: []
  author_blocks: []

  constructor: ->
    @getData()

  getData: ->
    d3.json 'http://localhost:3000/data.json', (data) =>
      #console.log data
      
      for blame in data.blame_data
        @commit_blocks.push(new CommitBlock(blame))

      for author, commits of data.author_data
        @author_blocks.push(new AuthorBlock(author, commits))

      @putHTML()

  putHTML: ->
    @commit_blocks.forEach (c) ->
      $("#chart").append(c.getHTML())

    @author_blocks.forEach (a) ->
      $("#sidebar").append(a.getHTML())

$ ->
  controller = new Controller
