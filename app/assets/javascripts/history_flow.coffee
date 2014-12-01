class window.HistoryFlow
  constructor: (data) ->
    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()

    x = d3.scale.ordinal().rangeBands([0, WIDTH])
    y = d3.scale.linear().range([0, HEIGHT])

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
      .on("click", ->
        filtered_data = data.blame_data
        updater()
      )

    updater = () ->
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
        .style("fill", (d) -> Util.generateColor(d.commit_id))
        .attr("width", x.rangeBand())
        .attr("y", 0)
        .attr("height", 0)
        .transition()
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))

      blame_block
        .on("mouseover", (d, i) ->
          d3.select(this).classed("hover_blame_block", true)
          blame_block.classed("faded_blame_block", (blame) -> blame.commit_id != d.commit_id)
          blame_div = $(".blame_#{d.blame_id}")
          blame_pos = blame_div.position()

          scroll_left = $("#code_blocks").scrollLeft()
          scroll_top = $("#code_blocks").scrollTop()

          middle_left = $("#code_blocks").width() / 2
          middle_top = 0

          $("#code_blocks").clearQueue().animate
            scrollLeft: blame_pos.left + scroll_left - middle_left
            scrollTop: blame_pos.top + scroll_top - middle_top

          blame_div.addClass('highlight_blame')
        )

        .on("mouseout", (d) ->
          d3.select(this).classed("hover_blame_block", false)
          blame_block.classed("faded_blame_block", false)
          $(".blame_#{d.blame_id}").removeClass('highlight_blame')
        )
        .on("click", (d) ->
          filtered_data = filtered_data.map((commit_block) -> {
            commit_id: commit_block.commit_id,
            blame_content_array: commit_block.blame_content_array.filter (obj) -> obj.commit_id == d.commit_id
          }).filter (commit_block) -> commit_block.blame_content_array.length != 0
          updater()
        )

      blame_block
        .exit()
        .remove()

    updater()
