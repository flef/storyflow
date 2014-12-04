class window.Util
  @generateColor: (commit_id) ->
    return "##{commit_id.substr(0, 6)}"

  @generateRGBA: (commit_id, alpha = 0.2) ->
    r = parseInt(commit_id.substr(0, 2), 16)
    g = parseInt(commit_id.substr(2, 2), 16)
    b = parseInt(commit_id.substr(4, 2), 16)

    return "rgba(#{r}, #{g}, #{b}, #{alpha})"
