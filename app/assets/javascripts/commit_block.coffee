class window.CommitBlock
  constructor: (@blame_data) ->
    #console.log @blame_data
  
  getHTML: =>
    commit_block = (html) ->
      "<div class='cb_commit'>#{html}</div>"

    blame_block = (commit_id, blame_id, html) ->
      "<div class='cb_blame commit_#{commit_id} blame_#{blame_id}' 
        style='background-color: ##{Util.generateColor(commit_id)}'>
        #{html}
      </div>"

    code_block = (code) ->
      if code == "" then code = " "
      "<div class='code_block'><pre>#{code}</pre></div>"

    blames = @blame_data.blame_content_array.map (blame) ->
      #console.log commit
      codes = blame.content.map (line) ->
        code_block(line)

      blame_block(blame.commit_id, blame.blame_id, codes.join(""))

    return commit_block(blames.join(""))
