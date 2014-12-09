class window.SankeyFlow
  constructor: (@data) ->
    console.log  @data

    margin =
      top: 0
      right: 0
      bottom: 0
      left: 0

    width = 3000 - margin.left - margin.right
    height = 5000 - margin.top - margin.bottom

    curvature = .2

    lineHeight = 14
    lineWidth = 500
    spaceBetweenLines = 100

    BLOCK_WIDTH = lineWidth
    MARGIN = spaceBetweenLines

    blameY = (blameID, firstY = false) ->
      console.log "#blame_" + blameID
      if firstY
        d3.select("#blame_" + blameID).data()[0].y0 * lineHeight +
        d3.select("#blame_" + blameID).data()[0].content.length * lineHeight / 2
      else
        d3.select("#blame_" + blameID).data()[0].y0 * lineHeight 
        #+ d3.select("#blame_" + blameID).data()[0].content.length * lineHeight / 2

    path = (d) ->
      x0 = 0
      x1 = MARGIN
      xi = d3.interpolateNumber(x0, x1)
      x2 = xi(curvature)
      x3 = xi(1 - curvature)
      y0 = blameY(d.src, true) 
      y1 = blameY(d.dst)+ d.start_line_number * lineHeight + d.lines_number * lineHeight / 2
      "M" + x0 + "," + y0 + "C" + x2 + "," + y0 + " " + x3 + "," + y1 + " " + x1 + "," + y1

    d3.select("#code_blocks").selectAll(".svg_container")
        .data(d3.entries(@data))
        .enter()
          .append("svg")
          .style("left", (d, i) -> ((i + 1) * (MARGIN + BLOCK_WIDTH) - MARGIN) + "px")
          .attr("width", MARGIN)
          .attr("height", "3000px")
          .attr("class", "svg_container")
          .append("g")
        .selectAll(".path")
          .data((d) -> d.value)
          .enter()
            .append("path")
            .attr("class", "link")
            .attr("d", path)
            .attr("data-info", 
              (d) -> 
                console.log d.info
                d.info
              )
            .style("stroke-width", 
             (d) ->
               (lineHeight) * d.lines_number
             )

###*

    d3.select("#code_blocks").selectAll(".link")
        .data(@data)
        .enter()
          .append("svg")
          .append("g")
            .data((d) -> d)
            .enter()
              .append("path")


        .style("left", (d, i) -> "#{i * (BLOCK_WIDTH + MARGIN)}px")
        .data(@data)
        .enter()
          .append("svg")
          .append("g")
          .append("path")
         .attr("class", "link")
         .attr("d", path)
         .style("stroke-width", 
          (d) ->
            lineHeight * d.dY
          )

###


###*
class AuthorBlock
  constructor: (@author_name, @commit_data) ->
    #console.log @author_name, @commit_data

  getHTML: ->
    author_block = (html) =>
      "<div class='author_block'>
        <div class='author_info'>
          #{@author_name}: #{@commit_data.length} commits
        </div>
        #{html}
      </div>"

    commit_block = (commit_id, html) ->
      #"<div class='author_commit_block hidden'>#{html}</div>"
      "<div class='author_commit_block commit_#{commit_id}'>
      #{html}
      </div>"

    commits = @commit_data.map (commit) ->
      commit_block(commit.id.substr(0, 6), "#{commit.id.substr(0, 6)}: #{commit.message}")

    return author_block(commits.join(""))

$ ->
  window.controller = new Controller
###