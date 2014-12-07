class window.SidebarInfo
  constructor: ->

  setInfo: (commit) ->
    $("#commit_info_user_gravatar > img")
      .attr("src", "https://github.com/identicons/#{commit.gravatar}.png")
    $("#commit_info_user_name > h5").html(commit.committer_name)
    $("#commit_info_message > p").html(commit.message)

    console.log commit

  removeInfo: ->
    $("#commit_info_user_gravatar > img").attr("src", "")
    $("#commit_info_user_name > h5").html("")
    $("#commit_info_message > p").html("")
