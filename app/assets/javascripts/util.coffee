RIGHT_COLOR_SCALE = "#FDFFCB"
LEFT_COLOR_SCALE = "#232942"

class window.Util
  color_obj: null

  constructor: (number_of_commits) ->
    @color_obj = d3.scale.linear()
      .range([LEFT_COLOR_SCALE, RIGHT_COLOR_SCALE])
      .domain([0, number_of_commits])
      .interpolate(d3.interpolateHsl)

    @author_color_obj = d3.scale.category10()

  color: (commit_num) -> @color_obj(commit_num)

  author_color: (author_num) -> @author_color_obj(author_num)

  stacker: (input_data) ->
    for d in input_data
      y0 = 0
      d.blame_content_array = d.blame_content_array.map (obj) ->
        obj.y0 = y0
        y0 += obj.lines
        return obj
      d.total_line_count = y0

    return input_data
