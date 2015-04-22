    // drow barchart with 5 biggest partners for the firm
    function barChart(jsondata, w, h, p, t){
	// TODO: generate this part in erb 
        var data = jsondata.map(function(d){return d[1];});         
	var names = jsondata.map(function(d){return d[0];}); 
        //var ids = jsondata.map(function(d){return d[2];});  
        var total_volume = d3.sum(data); 
	// eof erb
        // buyer or seller? 
	var b_or_s = 'buyer'; 
        if(window.location.href.indexOf("buyer") > -1) {
	   b_or_s = 'seller';	
        }

        var adata = jsondata.map(function(d, i) {
                        return { x: d[1],  name: d[0], id: d[2]};
                });

        var max_vol = d3.max(data);
        var bar_length = 30, bar_height = 10,
            numb_of_points = data.length,
                y = d3.scale.linear().domain([0, numb_of_points-1]).range([h, 20]),
                x = d3.scale.linear().domain([0, max_vol]).range([0, w/3]);
        


       var vis = d3.select("#barchart")
                                .append("div")
                                  .attr("class", function() { 
                                        return "barchart";
                                  })

                                .append("svg:svg")
                                    .attr("width", w + p * 2)
				    .attr("height", h + p * 2)
                                    .append("svg:g")
                                    .attr("transform", "translate(" + (p+20) + "," + p + ")");


                        var rules = vis.selectAll("g.rule")
                            .data([0, max_vol / 2, max_vol])
                          .enter().append("svg:g")
                            .attr("class", "rule");

                        rules.append("svg:line")
                            .attr("x1", x)
                            .attr("x2", x)
                            .attr("y1", 10)
                            .attr("y2", h-1);

                        vis.append("svg:text")
                                .attr("x", 0)
                                .text(t)
                                .attr("class", "aheader");

                        vis.append("svg:text")
                                .attr("x", -40)
                                .text("млн.")
                                .attr("class", "aheader");

 			rules.append("svg:text")
                                .attr("class", "ticklabel")
                                .attr("y", h+2)
                                .attr("x", x)
                                .attr("dx", 8)
                                .attr("dy", 11)
                                .attr("text-anchor", "middle")
                                .text(function(d,i){ return i == 0 ? '' :
						d3.round(100 * d / total_volume) + "%";});


			// our horisontal bars of different lengths
			    vis.selectAll("rect")
     				.data(adata)
   				.enter().append("rect")
                                    .attr("x", 0 )  
     				    .attr("y", function(d, i) { return y(i) - bar_height; }) 
     				    .attr("width", function(d) { return x(d.x); })
     				    .attr("height", bar_height);

			// actually, right labels (name of comps)
			 var right_txts = vis.selectAll("g.rtext")
				.data(adata)
                        	.enter().append("svg:text")
                                        .attr("class", "rtext")
                                	.attr("x", x(max_vol) + 20 )
                                	.attr("y", function(d, i) { return y(i); })
                                	.text(function(d) { return d.name;})
                                        .on('click', function(d){ window.open('http://z.texty.org.ua/' + 
						b_or_s + '/' + d.id,'_blank') })   
                                	.attr("text-anchor", "right");

			// left labels (volume)
			 var left_txts = vis.selectAll("g.ltext")
				.data(adata)
                        	.enter().append("svg:text")
                                        .attr("class", "ltext")
                                	.attr("x", -40 )
                                	.attr("y", function(d, i) { return y(i); })
                                	.text(function(d) { return d3.format(".1f")(d.x/1000000);});


       }
