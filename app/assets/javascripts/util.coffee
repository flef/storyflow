class window.Util
  @generateColor: (commit_id) ->
    return "##{commit_id.substr(0, 6)}"
