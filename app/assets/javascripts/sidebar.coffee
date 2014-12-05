class window.Sidebar
	
  constructor: (@data) ->
    for commit in @data.history
      console.log commit   
      $("ul.sidebar-nav").append("
        <li class='menu commit_#{commit.id.substr(0, 8)}'>
        <img class='menu_gravatar img-rounded' src='http://www.gravatar.com/avatar/#{commit.gravatar}' />
        #{commit.message.substr(0, 50)} </li>"
      )
      continue

      $(document).ready -> # off-canvas sidebar toggle
        $("[data-toggle=offcanvas]").click ->
          $(this).toggleClass "visible-xs text-center"
          $(this).find("i").toggleClass "glyphicon-chevron-right glyphicon-chevron-left"
          $(".row-offcanvas").toggleClass "active"
          $("#lg-menu").toggleClass("hidden-xs").toggleClass "visible-xs"
          $("#xs-menu").toggleClass("visible-xs").toggleClass "hidden-xs"
          $("#btnShow").toggle()
          return
      return

    $(".menu").on "click", (e) ->
      commit = e.target.className.split(" ")[1]
      $("##{commit}").hide()



