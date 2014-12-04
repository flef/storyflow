class window.HistoryFlow
  state: "NORMAL"
  constructor: (data) ->
    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()
    SATURATION = 0.8
    LUMINANCE = 0.4

    x = d3.scale.ordinal().rangeBands([0, WIDTH])
    y = d3.scale.linear().range([0, HEIGHT])

    nbCommit = data.history_data.numberOfCommit

    colorScale = d3.scale.linear().domain([1,22]).range([0, 359])   
    color = (x) -> d3.hsl(colorScale(x), SATURATION, LUMINANCE)


    svg = d3.select("#history_flow")
      .append("svg")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)

    filtered_data = data.blame_data
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
        filtered_data = data.blame_data
        updater()
      )

    updater = =>
      stacked_data = stacker(filtered_data)
      x.domain(stacked_data.map (d) -> d.commit_id)
      y.domain([0, d3.max(stacked_data, (d) -> d.total_line_count)])

      commit_block = svg.selectAll(".hf_commit")
        .data(stacked_data, (d) -> d.commit_id)

      commit_block
        .enter().append("g")
        .attr("class", (d) -> "hf_commit commit_#{d.commit_id}")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      commit_block
        .transition()
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      commit_block
        .exit()
        .remove()

      blame_block = commit_block.selectAll("rect")
        .data(((d) -> d.blame_content_array), (d) -> d.blame_id)

      blame_block
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))
        .attr("width", x.rangeBand())



      blame_block
        .enter()
        .append("rect")
        .attr("class", (d) -> "hf_blame_block_#{d.commit_id}")
        .style("fill", (d) -> color(d.commit_number))
        .attr("width", x.rangeBand())
        .attr("y", 0)
        .attr("height", 0)
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))
        .style("stroke-width", (d) -> if y(d.y0 + d.lines) - y(d.y0) < 2 then 0 else 0.3)
        .style("stroke", "white")

      blame_block
        .on("mouseover", (d, i) ->
          d3.select(this).classed("hover_blame_block", true)

          blame_block.classed("faded_blame_block", (blame) -> blame.commit_id != d.commit_id)
          blame_div = $(".blame_#{d.blame_id}")
          blame_pos = blame_div.position()

          scroll_left = $("#code_blocks").scrollLeft()
          scroll_top = $("#code_blocks").scrollTop()

          MARGIN_LEFT = 50
          MARGIN_TOP = 20

          middle_left = $("#code_blocks").width() / 2 - MARGIN_LEFT

          $("#code_blocks").clearQueue().animate
            scrollLeft: blame_pos.left + scroll_left - middle_left
            scrollTop: blame_pos.top + scroll_top - MARGIN_TOP

          $(".cb_commit .commit_#{d.commit_id}").not(blame_div)
            .css("background-color", color(d.commit_number))

          blame_div
            .css("background-color", color(d.commit_number))
            .addClass('highlight_blame')
        )

        .on("mouseout", (d) ->
          d3.select(this).classed("hover_blame_block", false)
          blame_block.classed("faded_blame_block", false)
          $(".cb_commit .commit_#{d.commit_id}").css("background-color", "")
          $(".blame_#{d.blame_id}").removeClass('highlight_blame')
        )
        .on("click", (d) =>
          console.log d
          console.log @state
          if @state is "NORMAL"
            filtered_data = filtered_data.map((commit_block) -> {
              commit_id: commit_block.commit_id,
              blame_content_array: commit_block.blame_content_array.filter (obj) -> obj.commit_id == d.commit_id
            }).filter (commit_block) -> commit_block.blame_content_array.length != 0
            updater()
            @state = "ENLARGED"

          else if @state is "ENLARGED"
            $(".cb_blame").not(".commit_#{d.commit_id}").slideUp()
        )

      blame_block
        .exit()
        .remove()

    updater()
