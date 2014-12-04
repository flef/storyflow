BLOCK_WIDTH = 500
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

    commit_block = div.selectAll(".cb_commit")
      .data(stacked_data, (d) -> d.commit_id)

    commit_block
      .enter().append("div")
      .attr("id", (d) -> "commit_#{d.commit_id}")
      .attr("class", (d) -> "cb_commit")
      .style("transform", (d, i) -> "translate(#{i * BLOCK_WIDTH}px, 0)")

    blame_block = commit_block.selectAll(".cb_blame")
      .data(((d) -> d.blame_content_array), (d) -> d.blame_id)

    blame_block
      .enter()
      .append("div")
      .attr("id", (d) -> "blame_#{d.blame_id}")
      .attr("class", (d) -> "cb_blame commit_#{d.commit_id}")
      .style("transform", (d, i) -> "translate(0, #{d.y0 * PRE_HEIGHT}px)")

    code_block = blame_block.selectAll("cb_code_block")
      .data((d) -> d.content)

    code_block
      .enter()
      .append("pre")
      .attr("class", "cb_code_block")
      .text((d) -> d)

