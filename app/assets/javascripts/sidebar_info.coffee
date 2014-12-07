class window.SidebarInfo
  constructor: ->
    @util = new Util()

  setInfo: (commit) ->
    $("#commit_info_user_gravatar > img")
      .attr("src", "https://github.com/identicons/#{commit.gravatar}.png")
    $("#commit_info_user_name > h5").html(commit.committer_name)
    $("#commit_info_message > p").html(commit.message)

  removeInfo: ->
    $("#commit_info_user_gravatar > img").attr("src", "")
    $("#commit_info_user_name > h5").html("")
    $("#commit_info_message > p").html("")

  setAuthorData: (author) ->
    for k, v of author
      console.log k, v
      author_number = v

      $("#author_information").append("
      <div class='author_color'>
        <div class='author_info'>
          #{k}, #{v}
        </div>
        <div class='author_color_tab'
          style='background-color:#{@util.author_color(author_number)}'>
        </div>
      </div>
        ")
