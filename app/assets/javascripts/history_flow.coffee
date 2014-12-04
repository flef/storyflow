class window.HistoryFlow
  state: "NORMAL"
  constructor: (data, numberOfCommit) ->
    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()

    SCALE_HANDLE_HEIGHT = 25
    SCALE_HANDLE_MARGIN = SCALE_HANDLE_HEIGHT + 2

    RIGHT_COLOR_SCALE = "#FDFFCB"
    LEFT_COLOR_SCALE = "#232942"

    x = d3.scale.ordinal().rangeBands([0, WIDTH])
    y = d3.scale.linear().range([0, HEIGHT - SCALE_HANDLE_MARGIN])

    color = d3.scale.linear()
             .range([LEFT_COLOR_SCALE, RIGHT_COLOR_SCALE])
             .domain([0, data.length])
             .interpolate(d3.interpolateHsl)

    svg = d3.select("#history_flow")
      .append("svg")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)

    div = d3.select("#code_blocks")

    filtered_data = data

    stacker = (input_data) ->
      for d in input_data
        y0 = 0
        d.blame_content_array = d.blame_content_array.map (obj) ->
          obj.y0 = y0
          y0 += obj.lines
          return obj
        d.total_line_count = y0

      return input_data
    
    svg_bottom_handler = svg.append("rect")
      .attr("fill", "white")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)
      .on("click", =>
        @state = "NORMAL"
        $(".cb_blame").show()
        filtered_data = data
        updater()
      )

    updater = =>
      stacked_data = stacker(filtered_data)
      x.domain(stacked_data.map (d) -> d.commit_id)
      y.domain([0, d3.max(stacked_data, (d) -> d.total_line_count)])



      hf_scale_handle = svg.selectAll(".hf_scale_handle")
        .data(stacked_data, (d) -> d.commit_id)

      hf_scale_handle
        .enter()
        .append("rect")
        .attr("class", (d) -> "hf_scale_handle")
        .style("fill", (d, i) -> color(i))
        .attr("width", x.rangeBand())
        .attr("y", 0)
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")
        .attr("height", SCALE_HANDLE_HEIGHT)
        .on("mouseover", (d) ->
          d3.select(this).classed("hover_block", true)
          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", true))
        .on("mouseout", (d) ->
          d3.select(this).classed("hover_block", false)
          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", false))


      hf_commit = svg.selectAll(".hf_commit")
        .data(stacked_data, (d) -> d.commit_id)

      hf_commit
        .enter().append("g")
        .attr("class", (d) -> "hf_commit commit_#{d.commit_id}")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, #{SCALE_HANDLE_MARGIN})")

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
        .attr("class", (d) -> "hf_blame hf_blame_block_#{d.commit_id}")
        .style("fill", (d) -> color(d.commit_number))
        .attr("width", x.rangeBand())
        .attr("y", 0)
        .attr("height", 0)
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))

      hf_blame
        .on("mouseover", (d, i) ->
          d3.select(this).classed("hover_block", true)

          hf_blame.classed("faded_blame_block", (blame) -> blame.commit_id != d.commit_id)
          blame_div = $("#blame_#{d.blame_id}")
          commit_div = blame_div.parent()

          blame_x = parseInt(commit_div.css("transform").split(",")[4])
          blame_y = parseInt(blame_div.css("transform").split(",")[5])
          
          MARGIN_LEFT = 50
          MARGIN_TOP = 20

          middle_left = $("#code_blocks").width() / 2 - blame_div.width() / 2
          $("#code_blocks").clearQueue().animate
            scrollLeft: blame_x - middle_left
            scrollTop: blame_y - MARGIN_TOP

          $(".cb_commit .commit_#{d.commit_id}").not(blame_div)
            .css("background-color", color(d.commit_number))

          blame_div
            .css("background-color", color(d.commit_number))
            .addClass('highlight_blame'))

        .on("mouseout", (d) ->
          d3.select(this).classed("hover_block", false)
          hf_blame.classed("faded_blame_block", false)
          $(".cb_commit .commit_#{d.commit_id}").css("background-color", "")
          $("#blame_#{d.blame_id}").removeClass('highlight_blame'))

        .on("click", (d) =>
          if @state is "NORMAL"
            filtered_data = filtered_data.map((commit_block) -> {
              commit_id: commit_block.commit_id,
              blame_content_array: commit_block.blame_content_array.filter (obj) -> obj.commit_id == d.commit_id
            }).filter (commit_block) -> commit_block.blame_content_array.length != 0

            updater()
            @state = "ENLARGED"

          else if @state is "ENLARGED"
            $(".cb_blame").not(".commit_#{d.commit_id}").slideUp())

      hf_blame
        .exit()
        .remove()

    updater()
