MARGIN = 50
SCROLL_MARGIN_LEFT = 50
SCROLL_MARGIN_TOP = 20

BLOCK_WIDTH = 500
PRE_HEIGHT = 14
SCALE_HANDLE_HEIGHT = 25
CURRENT_COMMITS_HEIGHT = 2
SCALE_HANDLE_MARGIN = SCALE_HANDLE_HEIGHT + CURRENT_COMMITS_HEIGHT

#RIGHT_COLOR_SCALE = "#FDFFCB"
LEFT_COLOR_SCALE = "#FDFFCB"
RIGHT_COLOR_SCALE = "#232942"

class window.HistoryFlow
  state: "NORMAL"
  width: 0
  height: 0
  data: null

  stacker: (input_data) ->
    for d in input_data
      y0 = 0
      d.blame_content_array = d.blame_content_array.map (obj) ->
        obj.y0 = y0
        y0 += obj.lines
        return obj
      d.total_line_count = y0

    return input_data

  constructor: (@data, numberOfCommit) ->
    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()

    console.log @data

    selected_index = null
    filtered_data = @data

    #isOnScreen = (elem) ->
      #console.log $("#code_blocks").scrollLeft(), $(elem).left()

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
      filtered_data = @data
      selected_index = null

    updater = =>
      stacked_data = @stacker(filtered_data)
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

      cb_blame
        .enter()
        .append("div")
        .attr("id", (d) -> "blame_#{d.blame_id}")
        .attr("class", (d) -> "cb_blame commit_#{d.commit_id}")
        .style("transform", (d, i) -> "translate(0, #{d.y0 * PRE_HEIGHT}px)")
        .on("mouseover", (d) ->
          hf_blame.classed("faded_blame_block", (blame) -> blame.commit_id != d.commit_id)
          hf_blame.classed("hover_block", (blame) -> blame.blame_id == d.blame_id)
          $(".cb_commit .commit_#{d.commit_id}")
            #.not(this)
            .css("background-color", color(d.commit_number))
        )
        .on("mouseout", (d) ->
          hf_blame.classed("faded_blame_block", false)
          $(".cb_commit .commit_#{d.commit_id}")
            .css("background-color", "")
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
        .attr("width", x.rangeBand())

      hf_scale_handle
        .enter()
        .append("rect")
        .attr("class", (d) -> "hf_scale_handle")
        .style("fill", (d, i) -> color(i))
        .attr("width", x.rangeBand())
        .attr("height", SCALE_HANDLE_HEIGHT)
        .attr("y", 0)
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")
        .on("mouseover", (d) ->
          d3.select(this).classed("hover_block", true)
          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", true))
        .on("mouseout", (d) ->
          d3.select(this).classed("hover_block", false)
          d3.select(".hf_commit.commit_#{d.commit_id}").classed("hover_block", false))
        .on("click", (d, i) ->
          if d3.select(this).classed("selected_block")
            d3.select(this).classed("selected_block", false)
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

      hf_current_commits = svg.select("#hf_current_commits_container")
        .selectAll(".hf_current_commits")
        .data(stacked_data, (d) -> d.commit_id)

      hf_current_commits
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
        .on("mouseover", (d) -> hf_scale_handle.classed("selectd_block", (handle) -> handle.commit_id == d.commit_id ))

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
