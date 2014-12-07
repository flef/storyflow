MARGIN = 50
SCROLL_MARGIN_LEFT = 50
SCROLL_MARGIN_TOP = 20

BLOCK_WIDTH = 500
PRE_HEIGHT = 14
SCALE_HANDLE_HEIGHT = 50
CURRENT_COMMITS_HEIGHT = 5
SCALE_HANDLE_MARGIN = SCALE_HANDLE_HEIGHT + CURRENT_COMMITS_HEIGHT

OPACITY_DURATION = 120
IDLE_OPACITY = 0.2

class window.HistoryFlow
  state: "NORMAL"
  menu_item: "HISTORY"
  data: null

  constructor: (data) ->
    console.log data

    selected_index = null

    blame_data = data.blame_data
    history_data = data.history_data
    filtered_data = blame_data
    remainders_data = data.remainders_data
    console.log remainders_data

    redraw = ->
      temp_data = filtered_data
      filtered_data = []
      updater()
      filtered_data = temp_data
      updater()

    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()

    $("#history-toggle").click (e) =>
      $(e.target).addClass("btn-danger")
      $("#author-toggle").removeClass("btn-danger")
      @menu_item = "HISTORY"
      redraw()
      $("#commit_information").show()
      $("#author_information").hide()

    $("#author-toggle").click (e) =>
      $(e.target).addClass("btn-danger")
      $("#history-toggle").removeClass("btn-danger")
      @menu_item = "AUTHOR"
      redraw()
      $("#commit_information").hide()
      $("#author_information").show()

    sidebar_info = new SidebarInfo()
    sidebar_info.setAuthorData(data.author_data)

    util = new Util(blame_data.length)

    x = d3.scale.ordinal().rangeBands([0, WIDTH])
    y = d3.scale.linear().range([0, HEIGHT - SCALE_HANDLE_MARGIN])

    svg = d3.select("#history_flow")
      .append("svg")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)

    svg.append("rect")
      .attr("fill", "white")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)
      .on "click", =>
        @state = "NORMAL"
        $(".cb_blame").show()
        selected_index = null
        reset()
        updater()

    svg.append("g")
      .attr("id", "hf_scale_handle_container")

    svg.append("g")
      .attr("id", "hf_current_commits_container")

    div = d3.select("#code_blocks")

    getCommitsOnScreen = ->
      code_blocks = $("#code_blocks")
      scroll_left = code_blocks.scrollLeft()
      screen_width = code_blocks.width()

      start = Math.floor(scroll_left / (BLOCK_WIDTH + MARGIN)) + 1
      end = Math.floor((scroll_left + screen_width) / (BLOCK_WIDTH + MARGIN)) + 1

      svg
        .selectAll(".hf_current_commits")
        .attr("fill", "black")
        .filter(":nth-child(n+#{start}):nth-child(-n+#{end})")
        .attr("fill", "red")

    $("#code_blocks").scroll (e) ->
      getCommitsOnScreen()

    reset = =>
      d3.selectAll(".hf_scale_handle").classed("selected_block", false)
      filtered_data = blame_data
      selected_index = null

    updater = =>
      stacked_data = util.stacker(filtered_data)
      x.domain(stacked_data.map (d) -> d.commit_id)
      y.domain([0, d3.max(stacked_data, (d) -> d.total_line_count)])

      cb_div = div.selectAll(".cb_commit")
        .data(stacked_data, (d) -> d.commit_id)

      cb_div
        .transition()
        .style("left", (d, i) -> "#{i * (BLOCK_WIDTH + MARGIN)}px")

      cb_div
        .enter()
        .append("div")
        .attr("id", (d) -> "commit_#{d.commit_id}")
        .attr("class", (d) -> "cb_commit")
        .style("left", (d, i) -> "#{i * (BLOCK_WIDTH + MARGIN)}px")
        .on("mouseover", (d) ->
          hf_scale_handle.classed("hover_block", (handle) -> handle.commit_id == d.commit_id))
        .on("mouseout", (d) ->
          hf_scale_handle.classed("hover_block", false))

      cb_div
        .exit()
       .remove()

      cb_blame = cb_div.selectAll(".cb_blame")
        .data(((d) -> d.blame_content_array), (d) -> d.blame_id)

      cb_blame
        .exit()
        .remove()

      cb_blame
        .style("transform", (d, i) -> "translate(0, #{d.y0 * PRE_HEIGHT}px)")
        .style("background-color", (d) =>
          if @menu_item is "AUTHOR"
            bg = d3.rgb(util.author_color(d.author_number))
            return "rgba(#{bg.r}, #{bg.g}, #{bg.b}, 0.2)"
          else
            bg = d3.rgb(util.color(d.commit_number))
            return "rgba(#{bg.r}, #{bg.g}, #{bg.b}, 0.2)")

      cb_blame
        .enter()
        .append("div")
        .attr("id", (d) -> "blame_#{d.blame_id}")
        .attr("class", (d) -> "cb_blame commit_#{d.commit_id}")
        .style("transform", (d, i) -> "translate(0, #{d.y0 * PRE_HEIGHT}px)")
        .style("background-color", (d) =>
          if @menu_item is "AUTHOR"
            bg = d3.rgb(util.author_color(d.author_number))
            return "rgba(#{bg.r}, #{bg.g}, #{bg.b}, 0.2)"
          else
            bg = d3.rgb(util.color(d.commit_number))
            return "rgba(#{bg.r}, #{bg.g}, #{bg.b}, 0.2)")
        .on("mouseenter", (d) =>
          commit_info = history_data.history[d.commit_number]
          sidebar_info.setInfo(commit_info)

          hf_blame
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 0.2)
          hf_blame
            .classed("hover_block", (blame) -> blame.blame_id == d.blame_id)
          d3.selectAll(".cb_commit .commit_#{d.commit_id}")
            .transition()
            .duration(OPACITY_DURATION)
            .styleTween("background-color",
              (d, i, a) =>
                start = null
                if @menu_item is "AUTHOR"
                  start = d3.rgb(util.author_color(d.author_number))
                else
                  start = d3.rgb(util.color(d.commit_number))

                start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
                end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
                return d3.interpolate(start_str, end_str)))
        .on("mouseleave", (d) =>
          sidebar_info.removeInfo()
          hf_blame
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 1)

          d3.selectAll(".cb_commit .commit_#{d.commit_id}")
            .transition()
            .duration(OPACITY_DURATION)
            .styleTween("background-color",
              (d, i, a) =>
                start = null
                if @menu_item is "AUTHOR"
                  start = d3.rgb(util.author_color(d.author_number))
                else
                  start = d3.rgb(util.color(d.commit_number))

                start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
                end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
                return d3.interpolate(start_str, end_str)))

        .on("dblclick", (d) =>
          if @state is "NORMAL"
            filtered_data = filtered_data.map((commit_block) -> {
              commit_id: commit_block.commit_id,
              blame_content_array: commit_block.blame_content_array.filter((obj) ->
                obj.commit_id == d.commit_id)
            }).filter (commit_block) -> commit_block.blame_content_array.length != 0

            @state = "ENLARGED"
            updater()
        )

      cb_code = cb_blame.selectAll(".cb_code_block")
        .data((d) -> d.content)

      cb_code
        .enter()
        .append("pre")
        .attr("class", "cb_code_block")
        .text((d) -> if d == "" then " " else d)

      hf_scale_handle = svg.select("#hf_scale_handle_container")
        .selectAll(".hf_scale_handle")
        .data(stacked_data, (d) -> d.commit_id)

      hf_scale_handle
        .exit()
        .remove()

      hf_scale_handle
        .transition()
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      hf_scale_handle
        .selectAll("rect")
        .transition()
        .attr("width", x.rangeBand())

      if (@state == "ENLARGED")
        $("#hf_scale_handle_container").hide()
      else
        $("#hf_scale_handle_container").show()

      scale_g = hf_scale_handle
        .enter()
        .append("g")
        .attr("class", (d) -> "hf_scale_handle")
        .attr("y", 0)
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")
        .on("mouseover", (d) ->
          d3.select(this).classed("hover_block", true)
          d3.select(this).select("rect:nth-child(2)")
            .attr("height", SCALE_HANDLE_HEIGHT)
            .attr("stroke-width", 0)
            .attr("y", 0)

          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", true)
          commit_info = history_data.history[history_data.history.length - d.commit_number]
          sidebar_info.setInfo(commit_info)
          svg
            .selectAll(".hf_blame")
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 0.2))
        .on("mouseout", (d) ->
          d3.select(this).classed("hover_block", false)
          d3.select(this).select("rect:nth-child(2)")
            .attr("stroke-width", 1)
            .attr("height", (d) => (remainders_data.commits[d.commit_id] || 0) * SCALE_HANDLE_HEIGHT)
            .attr("y", (d) ->
              height = (remainders_data.commits[d.commit_id] || 0) * SCALE_HANDLE_HEIGHT
              SCALE_HANDLE_HEIGHT - height)


          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", false)
          sidebar_info.removeInfo()
          svg
            .selectAll(".hf_blame")
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 1))
        .on("click", (d, i) ->
          if d3.select(this).classed("selected_block")
            d3.select(this).classed("selected_block", false)
            selected_index = null
          else
            d3.select(this).classed("selected_block", true)
            
            if selected_index != null
              range = [selected_index, i].sort (a, b) -> a > b
              filtered_data = filtered_data.slice(range[0], range[1] + 1)

              d3.selectAll(".hf_scale_handle").classed("selected_block", false)
              selected_index = null

              updater()
            else
              selected_index = i)

      scale_g
        .append("rect")
        .attr("height", SCALE_HANDLE_HEIGHT)
        .attr("width", x.rangeBand())
        .attr("fill", "white")

      scale_g
        .append("rect")
        .style("fill", (d, i) =>
          if @menu_item is "AUTHOR"
            util.author_color(d.author_number)
          else
            util.color(blame_data.length - i))
        .style("stroke", "black")
        .attr("width", x.rangeBand())
        .attr("height", (d) => (remainders_data.commits[d.commit_id] || 0) * SCALE_HANDLE_HEIGHT)
        .attr("y", (d) ->
          height = (remainders_data.commits[d.commit_id] || 0) * SCALE_HANDLE_HEIGHT
          SCALE_HANDLE_HEIGHT - height
        )

      svg.select("#hf_current_commits_container")
        .selectAll(".hf_current_commits")
        .remove() # Redraw the red bar everytime to ensure that the bars are in correct order

      hf_current_commits = svg.select("#hf_current_commits_container")
        .selectAll(".hf_current_commits")
        .data(stacked_data, (d) -> d.commit_id)
        .enter()
        .append("rect")
        .attr("class", "hf_current_commits")
        .attr("y", SCALE_HANDLE_HEIGHT)
        .attr("width", x.rangeBand())
        .attr("height", CURRENT_COMMITS_HEIGHT)
        .attr("fill", "black")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      hf_commit = svg.selectAll(".hf_commit")
        .data(stacked_data, (d) -> d.commit_id)

      hf_commit
        .enter().append("g")
        .attr("class", (d) -> "hf_commit commit_#{d.commit_id}")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, #{SCALE_HANDLE_MARGIN})")
        .on("mouseover", (d) ->
          hf_scale_handle.classed("hover_block", (handle) -> handle.commit_id == d.commit_id ))

      hf_commit
        .transition()
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, #{SCALE_HANDLE_MARGIN})")

      hf_commit
        .exit()
        .remove()

      hf_blame = hf_commit.selectAll(".hf_blame")
        .data(((d) -> d.blame_content_array), (d) -> d.blame_id)

      hf_blame
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))
        .attr("width", x.rangeBand())

      hf_blame
        .enter()
        .append("rect")
        .attr("id", (d) -> "hf_blame_#{d.blame_id}")
        .attr("class", (d) -> "hf_blame hf_blame_block_#{d.commit_id}")
        .style("fill", (d) =>
          if @menu_item is "AUTHOR"
            #console.log d.blame_id, d.author_number
            util.author_color(d.author_number)
          else
            util.color(d.commit_number))
        .attr("width", x.rangeBand())
        .attr("y", 0)
        .attr("height", 0)
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))

      hf_blame
        .on("mouseover", (d, i) =>
          commit_info = history_data.history[d.commit_number]
          sidebar_info.setInfo(commit_info)

          d3.select("#hf_blame_#{d.blame_id}").classed("hover_block", true)
          svg
            .selectAll(".hf_blame")
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 0.2)

          blame_div = $("#blame_#{d.blame_id}")
          blame_div
            .css("background-color", util.color(d.commit_number))
            .addClass('highlight_blame')

          d3.selectAll(".cb_commit .commit_#{d.commit_id}")
            .transition()
            .duration(OPACITY_DURATION)
            .styleTween("background-color",
              (d, i, a) =>
                start = null
                if @menu_item is "AUTHOR"
                  start = d3.rgb(util.author_color(d.author_number))
                else
                  start = d3.rgb(util.color(d.commit_number))

                start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
                end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
                return d3.interpolate(start_str, end_str)))

        .on("mouseout", (d) =>
          sidebar_info.removeInfo()
          d3.select("#hf_blame_#{d.blame_id}").classed("hover_block", false)
          svg
            .selectAll(".hf_blame")
            .filter((blame) -> blame.commit_id != d.commit_id)
            .transition()
            .duration(OPACITY_DURATION)
            .attr("opacity", 1)

          d3.selectAll(".cb_commit .commit_#{d.commit_id}")
            .transition()
            .duration(OPACITY_DURATION)
            .styleTween("background-color",
              (d, i, a) =>
                start = null
                if @menu_item is "AUTHOR"
                  start = d3.rgb(util.author_color(d.author_number))
                else
                  start = d3.rgb(util.color(d.commit_number))

                start_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.99)"
                end_str = "rgba(#{start.r}, #{start.g}, #{start.b}, 0.2)"
                return d3.interpolate(start_str, end_str))

          $("#blame_#{d.blame_id}").removeClass('highlight_blame'))

        .on("click", (d) ->
          blame_div = $("#blame_#{d.blame_id}")
          commit_div = blame_div.parent()

          blame_x = parseInt(commit_div.css("left"))
          blame_y = parseInt(blame_div.css("transform").split(",")[5])
          
          middle_left = $("#code_blocks").width() / 2 - blame_div.width() / 2

          $("#code_blocks").clearQueue().animate
            scrollLeft: blame_x - middle_left
            scrollTop: blame_y - SCROLL_MARGIN_TOP
        )

        .on("dblclick", (d) =>
          if @state is "NORMAL"
            filtered_data = filtered_data.map((commit_block) -> {
              commit_id: commit_block.commit_id,
              blame_content_array: commit_block.blame_content_array.filter((obj) ->
                obj.commit_id == d.commit_id)
            }).filter (commit_block) -> commit_block.blame_content_array.length != 0

            @state = "ENLARGED"
            updater())

      hf_blame
        .exit()
        .remove()

      getCommitsOnScreen()

    updater()
