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
    history_length = @data.history.length
    util = new Util(history_length)
    sidebar_info = new SidebarInfo()
    week = 0

    for commit, index in @data.history
      commit["commit_number"] = history_length - index

      #console.log commit
      #console.log week

      unless week is getWeekNumber commit.authored_date
        week = getWeekNumber commit.authored_date
        date = new Date(commit.authored_date)
        year = date.getFullYear()

        $("ul.sidebar-nav").append("
          <li class='menu_separator'>
          #{year} - week <b>#{getWeekNumber commit.authored_date}</b><hr/></li>"
        )

      $("ul.sidebar-nav").append("
        <li class='menu commit_#{commit.id}' 
          data-commit_id='#{commit.id}'
          data-commit_number='#{commit.commit_number}'>
        <img class='menu_gravatar img-rounded'
          src='https://github.com/identicons/#{commit.gravatar}.png'
          title='#{commit.author_name}'/>
        <span title='#{Date(commit.authored_date).toString()}'>
          #{commit.message.substr(0, 50)}
        </span>
        <div class='menu_color'
          style='background-color: #{util.color(commit.commit_number)}'>
        </div></li>")

    $("li.menu").on("mouseenter", (e) =>
      commit_id = $(e.target).data("commit_id")
      commit_number = $(e.target).data("commit_number")
      length = @data.history.length

      if commit_id # removes the sometimes appearing 'undefined'
        $(e.target).addClass("hover_menu")
        commit_data = @data.history[length - commit_number]
        sidebar_info.setInfo(commit_data)

        svg = d3.select("#history_flow > svg")
        svg
          .selectAll(".hf_blame")
          .filter((blame) -> blame.commit_id != commit_id)
          .transition()
          .duration(120)
          .attr("opacity", 0.2)

        d3.selectAll(".cb_commit .commit_#{commit_id}")
          .transition()
          .duration(120)
          .styleTween("background-color",
            (d, i, a) ->
              start = d3.rgb(util.color(d.commit_number))
              start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
              end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
              return d3.interpolate(start_str, end_str))

        d3.select(".hf_commit.commit_#{commit_id}").classed("hover_block", true))
    .on("mouseleave", (e) ->

      commit_id = $(this).data("commit_id")
      $(this).removeClass("hover_menu")
      sidebar_info.removeInfo()
      d3.select(".hf_commit.commit_#{commit_id}").classed("hover_block", false)
      svg = d3.select("#history_flow > svg")
      svg
        .selectAll(".hf_blame")
        .filter((blame) -> blame.commit_id != commit_id)
        .transition()
        .duration(120)
        .attr("opacity", 0.99)

      d3.selectAll(".cb_commit .commit_#{commit_id}")
        .transition()
        .duration(120)
        .styleTween("background-color",
          (d, i, a) ->
            start = d3.rgb(util.color(d.commit_number))
            start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
            end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
            return d3.interpolate(start_str, end_str)
        )
    )

    $("[data-toggle=offcanvas]").click -> # off-canvas sidebar toggle
      $(this).toggleClass "visible-xs text-center"
      $(this).find("i").toggleClass "glyphicon-chevron-right glyphicon-chevron-left"
      $(".row-offcanvas").toggleClass "active"
      $("#lg-menu").toggleClass("hidden-xs").toggleClass "visible-xs"
      $("#xs-menu").toggleClass("visible-xs").toggleClass "hidden-xs"
      $("#btnShow").toggle()

    $("#menu-toggle").click (e) ->
      e.preventDefault()
      $("#wrapper").toggleClass("toggled")


    #$("#menu-toggle").trigger("click")
