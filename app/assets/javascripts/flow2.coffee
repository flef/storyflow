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

      commit_blame = @svg.selectAll(".commit_blame")
        .data(data.blame_data)
        .enter().append("g")
        .attr("class", "g")
        .attr("transform", (d) -> "translate(#{x(d.commit_id)}, 0)")

      commit_blame.selectAll("rect")
        .data((d) -> d.blame_content_array)
        .enter().append("rect")
        .attr("width", x.rangeBand())
        .attr("y", (d) -> y(d.y0))
        .attr("height", (d) -> y(d.y0 + d.lines) - y(d.y0))
        .style("fill", (d) -> Util.generateColor(d.commit_id))

$ ->
  window.flow = new HistoryFlow
