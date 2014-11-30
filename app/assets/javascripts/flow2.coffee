#WIDTH = 500
#HEIGHT = 150

class HistoryFlow
  svg: null
  constructor: ->
    console.log "flow flow"
    WIDTH = $("#history_flow").width()
    HEIGHT = $("#history_flow").height()

    x = d3.scale.ordinal().rangeBands([0, WIDTH])
    y = d3.scale.linear().range([0, HEIGHT])

    @svg = d3.select("#history_flow")
      .append("svg")
      .attr("width", WIDTH)
      .attr("height", HEIGHT)

    d3.json "/data.json", (error, data) =>
      console.log data
      
      for d in data.blame_data
        y0 = 0

        d.blame_content_array = d.blame_content_array.map (obj) ->
          obj.y0 = y0
          y0 += obj.lines
          return obj

      x.domain(data.blame_data.map (d) -> d.commit_id)
      y.domain([0, d3.max(data.blame_data, (d) -> d.total_line_count)])

      commit_block = @svg.selectAll(".commit_blame")
        .data(data.blame_data)
        .enter().append("g")
        .attr("class", (d) -> "g commit_#{d.commit_id}")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      blame_block = commit_block.selectAll("rect")
        .data((d) -> d.blame_content_array)
        .enter().append("rect")
        .attr("class", (d) -> "blame_block_#{d.commit_id}")
        .attr("width", x.rangeBand())
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))
        .style("fill", (d) -> Util.generateColor(d.commit_id))
        .on("mouseover", (d) ->
          blame_block.classed("faded_blame_block", (blame) -> blame.commit_id != d.commit_id))
        .on("mouseout", (d) ->
          blame_block.classed("faded_blame_block", false)
        )
          #highlight = blame_block.filter (blame) -> blame.commit_id == d.commit_id
          #hide = blame_block.filter (blame) -> blame.commit_id != d.commit_id
          #hide.
          #hide.style("opacity", "0.4"))
        #.on("mouseout", (d) ->
          #blame
          #console.log "asdf"
        #)

$ ->
  window.flow = new HistoryFlow
