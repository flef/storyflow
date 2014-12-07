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
    for author_name, author_data of author
      console.log author_name, author_data
      author_number = author_data.author_num
      author_gravatar = author_data.author_gravatar

      $("#author_information").append("
      <div class='author_color'>
        <div class='author_info'>
          <img class='menu_gravatar img-rounded'
            src='https://github.com/identicons/#{author_gravatar}.png'
            title='#{author_name}'/>
          <span class='author_name'> #{author_name} </span>
        </div>
        <div class='author_color_tab'
          style='background-color:#{@util.author_color(author_number)}'>
        </div>
      </div>
        ")
