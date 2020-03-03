import * as d3 from 'd3';
import './plot.css';

function plotResults(data){
  //Element to append to will eventually be passed in by id
  let svg = d3.select("#output-section").append("svg");
  svg.attr("id", "tpafigure")
    .attr("xmlns","http://www.w3.org/2000/svg")
    .attr("version", "1.1")
    .attr("width", 720)
    .attr("height", 576)
    .attr("class", "bar-chart");

  //Create white background
  svg.append("rect")
    .attr("width", "100%")
    .attr("height", "100%")
    .attr("fill", "white");

  // Canvass Scoped settings
  let margin = {top: 40, right: 20, bottom: 60, left: 40, 
                middle_y: 40, middle_x: 20, xaxis: 10};
  let c_width = +svg.attr("width") - margin.left - margin.right;
  let c_height = +svg.attr("height") - margin.top - margin.bottom;

  // Main Plot 
  let main_plot = svg.append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  let main = { height: c_height, 
               width: c_width/2 - margin.middle_x }
  main.x = d3.scaleBand().rangeRound([0, main.width]).padding(0.1);
  main.y = d3.scaleLinear().rangeRound([main.height, 0]);

  main.x.domain( data.map( (d)=>{return(d.qtr_label)} ) );
  main.y.domain([0, 1.05*d3.max(data, (d)=>{ return d.med_d2rx; })]);

  main_plot.append("g")
    .attr("class", "axis axis--x")
    .attr("transform", "translate(0," + (main.height + margin.xaxis) + ")")
    .call(d3.axisBottom(main.x))
    .selectAll(".tick text")
    .call(axis_label_wrap);

  main_plot.append("g")
    .attr("class", "axis axis--y")
    .call(d3.axisLeft(main.y).ticks(10, "d"));

  main_plot.append("text")
    .attr("class", "axis")
    .attr("dy", "0.75em")
    .attr("text-anchor", "middle")
    .attr("transform", "translate("+ (-margin.left+2) + ","+ (main.height/2)+")rotate(-90)")
    .text("Time (minutes)");

  main_plot.selectAll(".bar")
    .data(data)
    .enter().append("rect")
      .attr("class", "bar bar-d2rx")
      .attr("x", function(d) { return main.x(d.qtr_label); })
      .attr("y", function(d) { return main.y(d.med_d2rx); })
      .attr("width", main.x.bandwidth())
      .attr("height", function(d) { return main.height - main.y(d.med_d2rx); });


  // SubPlot Scoped Settings
  // y-axis max is highets value in door 2 doctor and door 2 ct
  let sp_y_max = d3.max([
    d3.max(data, (d)=>{ return d.med_d2dr; }),
    d3.max(data, (d)=>{ return d.med_d2ct; })
  ]) * 1.05;

  // SubPlot 1
  let sp1_trans = { x: (c_width/2 + margin.left + margin.middle_x),
                    y: (margin.top) }
  let sp1 = { height: (c_height/2) - margin.middle_y,
              width: (c_width/2) - margin.middle_x}
  let sub_plot_1 = svg.append("g")
    .attr("transform","translate(" + sp1_trans.x + "," + sp1_trans.y + ")");

  sp1.x = d3.scaleBand().rangeRound([0, sp1.width]).padding(0.1);
  sp1.y = d3.scaleLinear().rangeRound([sp1.height, 0]);

  sp1.x.domain( data.map( (d)=>{return(d.qtr_label)} ) );
  sp1.y.domain([0, sp_y_max]);

  sub_plot_1.append("g")
    .attr("class", "axis axis--x")
    .attr("transform", "translate(0," + (sp1.height + margin.xaxis) + ")")
    .call(d3.axisBottom(sp1.x))
    .selectAll(".tick text")
    .call(axis_label_wrap);

  sub_plot_1.append("g")
    .attr("class", "axis axis--y")
    .call(d3.axisLeft(sp1.y).ticks(5, "d"));

  sub_plot_1.selectAll(".bar")
    .data(data)
    .enter().append("rect")
      .attr("class", "bar bar-d2dr")
      .attr("x", function(d) { return sp1.x(d.qtr_label); })
      .attr("y", function(d) { return sp1.y(d.med_d2dr); })
      .attr("width", sp1.x.bandwidth())
      .attr("height", function(d) { return sp1.height - sp1.y(d.med_d2dr); });

  // SubPlot 2: Door to CT
  let sp2_trans = { x: (c_width/2 + margin.left + margin.middle_x),
                    y: ((c_height/2) + margin.top + margin.middle_y) }
  let sp2 = { height: (c_height/2) - margin.middle_y,
              width: (c_width/2) - margin.middle_x}
  let sub_plot_2 = svg.append("g")
    .attr("transform","translate(" + sp2_trans.x + "," + sp2_trans.y + ")");

  sp2.x = d3.scaleBand().rangeRound([0, sp2.width]).padding(0.1);
  sp2.y = d3.scaleLinear().rangeRound([sp2.height, 0]);

  sp2.x.domain( data.map( (d)=>{return(d.qtr_label)} ) );
  sp2.y.domain([0, sp_y_max]);

  sub_plot_2.append("g")
    .attr("class", "axis axis--x")
    .attr("transform", "translate(0," + (sp2.height + margin.xaxis) + ")")
    .call(d3.axisBottom(sp2.x))
    .selectAll(".tick text")
      .call(axis_label_wrap);

  sub_plot_2.append("g")
    .attr("class", "axis axis--y")
    .call(d3.axisLeft(sp2.y).ticks(5, "d"))

  sub_plot_2.selectAll(".bar")
    .data(data)
    .enter().append("rect")
      .attr("class", "bar bar-d2ct")
      .attr("x", function(d) { return sp2.x(d.qtr_label); })
      .attr("y", function(d) { return sp2.y(d.med_d2ct); })
      .attr("width", sp2.x.bandwidth())
      .attr("height", function(d) { return sp2.height - sp2.y(d.med_d2ct); });


  // Plot Titles
  svg.append("text")
      .attr("class", "title-d2rx")
      .attr("x", c_width/4+margin.right)
      .attr("y", margin.top - 10)
      .attr("text-anchor", "middle")
      .text("Door to Treatment")

  svg.append("rect")
      .attr("class", "subtitle-bar")
      .attr("x", sp1_trans.x )
      .attr("y", margin.top - 30 )
      .attr("width", sp1.width)
      .attr("height", 30);

  svg.append("rect")
      .attr("class", "subtitle-bar")
      .attr("x", sp2_trans.x )
      .attr("y", c_height-sp2.height+10)
      .attr("width", sp2.width)
      .attr("height", 30);

  svg.append("text")
      .attr("class", "subtitle")
      .attr("x", c_width-(sp1.width/2)+margin.left)
      .attr("y", 0 + sp1_trans.y - 10)
      .attr("text-anchor", "middle")
      .text("Door to Doctor");

  svg.append("text")
      .attr("class", "subtitle")
      .attr("x", c_width-(sp2.width/2)+margin.left)
      .attr("y", 0 + sp2_trans.y - 10)
      .attr("text-anchor", "middle")
      .text("Door to CT");

}

function axis_label_wrap(ticksel){
  ticksel.each(function(){
    let ele = d3.select(this);
    let lines = ele.text().split(/\n/);
    let dy = parseFloat(ele.attr("dy"));
    let y  = ele.attr("y");
    ele.text(null);
    for (var i=0; i < lines.length; i++){
      ele.append("tspan")
        .attr("x", 0)
        .attr("y", y)
        .attr("dy", (dy + 1.1*i) +"em")
        .text(lines[i]);
    }
  });
}

function tabulate(data){

	let table = d3.select('#output-section').append('table')
	let thead = table.append('thead')
	let	tbody = table.append('tbody');

  let cols = Object.keys(data[0]);

	// append the header row
	thead.append('tr')
	  .selectAll('th')
	  .data(cols).enter()
	  .append('th')
	    .text(function (column) { return column; });

	// create a row for each object in the data
	let rows = tbody.selectAll('tr')
	  .data(data)
	  .enter()
	  .append('tr');

	// create a cell in each row for each column
	let cells = rows.selectAll('td')
	  .data(function (row) {
	    return cols.map(function (column) {
	      return {column: column, value: row[column]};
	    });
	  })
	  .enter()
	  .append('td')
	    .text(function (d) { return d.value; });

  return table;
}

export default {plotResults, tabulate};
