$(function(){
  var width = 3000
  var height = 1200

  var formatNumber = d3.format(",.0f");
  var format = function(d) { return formatNumber(d) + " TWh"; };
  var color = d3.scale.category20();

  var svg = d3.select("#chart").append("svg")
      .attr("width", width)
      .attr("height", height)
      .append("g")

  var sankey = d3.sankey()
      .nodeWidth(400)
      .nodePadding(0)
      .size([width, height]);

  var path = sankey.link();

  d3.json('http://localhost:3000/data.json', function (energy) {
    console.log(energy);

    sankey
      .nodes(energy.nodes)
      .links(energy.links)
      .layout(0);

    var link = svg.append("g").selectAll(".link")
      .data(energy.links)
      .enter().append("path")
      .attr("class", "link")
      .attr("d", path)
      .style("stroke-width", function(d) { return Math.max(1, d.dy); })
      .sort(function(a, b) { return b.dy - a.dy; });

    link.append("title")
      .text(function(d) { return d.source.name + " → " + d.target.name + "\n" + format(d.value); });

    var node = svg.append("g").selectAll(".node")
      .data(energy.nodes.sort( function(a,b) { return a.name < b.name; }))
      .enter().append("g")
      .attr("class", "node")
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })

    node.append("rect")
      .attr("height", function(d) { return d.dy; })
      .attr("width", sankey.nodeWidth())
      .style("fill", function(d) { return d.color = color(d.commit); })
      .style("stroke", function(d) { return d3.rgb(d.color).darker(2); })
      .append("title")
      .text(function(d) { return d.author; });

    node.append("text")
      .attr("y", function(d) { return 5; })
      .attr("dy", ".35em")
      .style("font-size", sankey.textsize() + "px")
      .attr("transform", null)
      .text(function(d) { return d.content; })
      .attr("x", 6 )
      .attr("text-anchor", "start");

    node.selectAll("text")
      .call(wrap, sankey.nodeWidth());
  });

  function wrap(text, width) {
    // nbVhar writable per line
    nbChar = 1.75 * sankey.nodeWidth() / sankey.textsize() - 5;

    text.each(function() {
      var text = d3.select(this)
      var lines = text.text().split(/\n/)
      var line
      var lineHeight = 0.5 // em
      var y = text.attr("y")
      var dy = parseFloat(text.attr("dy"));

      text.text(null);

      lines.forEach (function(line, lineNumber){
        var tab = line.match(/\t/g);
        
        if(line.length > nbChar) {
          line = line.substr(0, nbChar);
          line += "...";
        }
        
        text.append("tspan").attr("x", 0).attr("y", y).attr("dy", lineNumber * lineHeight + dy + "em").attr("text-indent", tab).text(line);
        });
      });
  }

})
