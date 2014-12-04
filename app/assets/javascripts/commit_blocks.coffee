BLOCK_WIDTH = 500
MARGIN = 50
PRE_HEIGHT = 14

class window.CommitBlocks
  constructor: (data) ->
    @update(data)

  stacker: (input_data) ->
    for d in input_data
      y0 = 0
      d.blame_content_array = d.blame_content_array.map (obj) ->
        obj.y0 = y0
        y0 += obj.lines
        return obj
      d.total_line_count = y0

    return input_data

  update: (filtered_data) =>
    stacked_data = @stacker(filtered_data)
    console.log stacked_data

    div = d3.select("#code_blocks")

    cb_div = div.selectAll(".cb_commit")
      .data(stacked_data, (d) -> d.commit_id)

    cb_div
      .enter().append("div")
      .attr("id", (d) -> "commit_#{d.commit_id}")
      .attr("class", (d) -> "cb_commit")
      .style("transform", (d, i) -> "translate(#{i * (BLOCK_WIDTH + MARGIN)}px, 0)")

    cb_blame = cb_div.selectAll(".cb_blame")
      .data(((d) -> d.blame_content_array), (d) -> d.blame_id)

    cb_blame
      .enter()
      .append("div")
      .attr("id", (d) -> "blame_#{d.blame_id}")
      .attr("class", (d) -> "cb_blame commit_#{d.commit_id}")
      .style("transform", (d, i) -> "translate(0, #{d.y0 * PRE_HEIGHT}px)")

    cb_code = cb_blame.selectAll("cb_code_block")
      .data((d) -> d.content)

    cb_code
      .enter()
      .append("pre")
      .attr("class", "cb_code_block")
      .text((d) -> d)

