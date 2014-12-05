class window.Sidebar
  getWeekNumber = (d) ->
    
    # Copy date so don't modify original
    d = new Date(+d)
    d.setHours 0, 0, 0
    
    # Set to nearest Thursday: current date + 4 - current day number
    # Make Sunday's day number 7
    d.setDate d.getDate() + 4 - (d.getDay() or 7)
    
    # Get first day of year
    yearStart = new Date(d.getFullYear(), 0, 1)
    
    # Calculate full weeks to nearest Thursday
    weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7)
    
    # Return week number
    weekNo
	
  constructor: (@data) ->

    week = 0
    for commit in @data.history
      console.log commit
      console.log week

      unless week is getWeekNumber commit.authored_date
        week = getWeekNumber commit.authored_date
        date = new Date(commit.authored_date)
        year = date.getFullYear()

        $("ul.sidebar-nav").append("
          <li class='menu_separator'>
          #{year} - week <b>#{getWeekNumber commit.authored_date}</b><hr/></li>"
        )

      $("ul.sidebar-nav").append("
        <li class='menu commit_#{commit.id.substr(0, 8)}'>
        <img class='menu_gravatar img-rounded' src='https://github.com/identicons/#{commit.gravatar}.png' title='#{commit.author_name}'/>
        <span title='#{Date(commit.authored_date).toString()}'>#{commit.message.substr(0, 50)}</span></li>"
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



