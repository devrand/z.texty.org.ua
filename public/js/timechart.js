    // simplae timechart for volumes 
    function timeChart(data, width, height, padding, title){     
	var w = width, h = height, p = padding;

        var labels = data.map(function(d){ return d[0]; });
        var data1 = data.map(function(d){ return d[1]; });
        // make main dataobject to display
        var adata = data.map(function(d, i) {
			return { x: i,  y: d[1] };
		});

        var max_vol = d3.max(data1);
	var areaClass = 'area';
	var numb_of_points = labels.length,
		x = d3.scale.linear().domain([0, numb_of_points-1]).range([15, w]),
		y = d3.scale.linear().domain([0, max_vol]).range([h, 20]);
	

	var area = d3.svg.area()
	    .x(function(d) { return x(d.x); })
	    .y0(h - 1)
	    .y1(function(d,i) { return y(d.y); });

       var vis = d3.select("#vis")
				.append("div")
				  .attr("class", function() { 
				 	return "chart noborder";
				  })

				.append("svg:svg")
				    .attr("width", w + p * 2)
				    .attr("height", h + p * 2)
				  .append("svg:g")
				    .attr("transform", "translate(" + p + "," + p + ")");


			var rules = vis.selectAll("g.rule")
			    .data(x.ticks(numb_of_points))
			  .enter().append("svg:g")
			    .attr("class", "rule");

			rules.append("svg:line")
			    .attr("x1", x)
			    .attr("x2", x)
			    .attr("y1", 10)
			    .attr("y2", h-1);

			rules.append("svg:line")
				.attr("class", "axis")
				.attr("y1", h)
				.attr("y2", h)
				.attr("x1", -11)
				.attr("x2", w+1);

			vis.append("svg:text")
				.attr("x", -12)
				.text(title)
				.attr("class", "aheader");

			rules.append("svg:text")
				.attr("class", "ticklabel")
				.attr("y", h)
				.attr("x", x)
				.attr("dx", 1)
				.attr("dy", 11)
				.attr("text-anchor", "middle")
				.text(function(d,i){ return i%2 == 0 ? labels[i] : '';});

			vis.append("svg:text")
				.attr("x", -3)
				.attr("y", h-4)
				.text("0")
				.attr("text-anchor", "right")
				.attr("class", "ticklabel");

			vis.append("svg:text")
				.attr("x", -13)
				.attr("y", 20)
				.text( d3.format(".2f")(max_vol/1000000) + 'млн.' )
				.attr("text-anchor", "right")
				.attr("class", "ticklabel1");


			vis.append("svg:path")
				.data([adata])
			    .attr("class", areaClass)
			    .attr("d", area); 
                  }
