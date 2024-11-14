/* 
Code source from:
INFO474 Lab4 code
Small multiple line charts: https://d3-graph-gallery.com/graph/line_smallmultiple.html
Line chart with confidence-interval: https://d3-graph-gallery.com/graph/line_confidence_interval.html
Line chart with cursor: https://d3-graph-gallery.com/graph/line_cursor.html
Thermometer.png: https://www.svgrepo.com/svg/115717/thermometer
*/

// **** Example of how to create padding and spacing for trellis plot****
var svg = d3.select('svg');

// Hand code the svg dimensions, you can also use +svg.attr('width') or +svg.attr('height')
var svgWidth = +svg.attr('width');
var svgHeight = +svg.attr('height');

// Define a padding object
// This will space out the trellis subplots
var padding = { t: 20, r: 20, b: 80, l: 60 };

// Compute the dimensions of the trellis plots, assuming a 2x2 layout matrix.
trellisWidth = svgWidth / 3 - padding.l - padding.r;
trellisHeight = svgHeight / 3 - padding.t - padding.b;

// As an example for how to layout elements with our variables
// Lets create .background rects for the trellis plots
svg.selectAll('.background')
    .data(['A', 'B', 'C', 'D', 'E', 'F', 'G']) // dummy data
    .enter()
    .append('rect')
    .attr('class', 'background')
    .attr('width', trellisWidth) // Use our trellis dimensions
    .attr('height', trellisHeight)
    .attr('transform', function (d, i) {
        // Position based on the matrix array indices.
        // i = 1 for column 1, row 0)
        var tx = (i % 3) * (trellisWidth + padding.l + padding.r) + padding.l;
        var ty = Math.floor(i / 3) * (trellisHeight + padding.t + padding.b) + padding.t;

        return 'translate(' + [tx, ty] + ')';
    });

var parseDate = d3.timeParse("%m/%d/%Y");
var tempDomain = [-30, 130];

// **** How to properly load data ****
d3.csv('Weather_Data.csv').then(function (dataset) {
    // **** Your JavaScript code goes here ****
    dataset.forEach(function (d) {
        d.date = parseDate(d.date);
    });
    console.log(dataset);
    var dateRange = d3.extent(dataset, function (d) { return d.date });

    let nested = d3.nest()
        .key(function (d) {
            return d.city;
        })
        .entries(dataset);
    console.log(nested)

    var city = svg.selectAll()
        .data(nested)
        .enter()
        .append('g')
        .attr('transform', function (d, i) {
            // Position based on the matrix array indices.
            // i = 1 for column 1, row 0)
            var tx = (i % 3) * (trellisWidth + padding.l + padding.r) + padding.l;
            var ty = Math.floor(i / 3) * (trellisHeight + padding.t + padding.b) + padding.t;
            return 'translate(' + [tx, ty] + ')';
        });

    let xScale = d3.scaleTime()
        .domain(dateRange)
        .range([0, trellisWidth])

    let yScale = d3.scaleLinear()
        .domain(tempDomain)
        .range([trellisHeight, 0]);

    let lineInterpolate = d3.line()
        .x(function (d) { return xScale(d.date) })
        .y(function (d) { return yScale(d.actual_mean_temp) })

    var xGrid = d3.axisTop(xScale)
        .tickSize(-trellisHeight, 0, 0)
        .tickFormat('');
    var yGrid = d3.axisLeft(yScale)
        .tickSize(-trellisWidth, 0, 0)
        .tickFormat('')

    city.append('g')
        .attr('class', 'x grid')
        .call(xGrid)
    city.append('g')
        .attr('class', 'y grid')
        .call(yGrid)

    let xScaleN = d3.axisBottom(xScale)
        .tickFormat(d3.timeFormat("%Y-%m-%d"))

    let yScaleN = d3.axisLeft(yScale)

    let colorScale = d3.scaleOrdinal(d3.schemeCategory10)


    city.each(function (d) {
        var filteredData = d.values.filter(function (d) {
            return !isNaN(d.actual_mean_temp) && !isNaN(d.record_min_temp) && !isNaN(d.record_max_temp);
        });
        console.log(filteredData);

        d3.select(this)
            .append('path')
            .datum(filteredData)
            .attr('class', 'line-plot')
            .attr('d', lineInterpolate)
            .style('stroke', '#333')
            .style("fill", "none")
            .style('stroke', colorScale(d.key))

        var area = d3.area()
            .x(function (d) { return xScale(d.date); })
            .y0(function (d) { return yScale(d.record_min_temp); })
            .y1(function (d) { return yScale(d.record_max_temp); });

        // with confidence-interval: https://d3-graph-gallery.com/graph/line_confidence_interval.html
        d3.select(this)
            .append('path')
            .datum(filteredData)
            .attr('class', 'confidence-interval')
            .attr('d', area)
            .style('fill', colorScale(d.key))
            .style('opacity', 0.1);

        // with cursor: https://d3-graph-gallery.com/graph/line_cursor.html
        // Create a group for focus elements
        var focusGroup = d3.select(this)
            .append('g')
            .style("opacity", 0);

        // Create the circle that travels along the curve of the chart
        var focusCircle = focusGroup
            .append('svg:image')
            .attr("xlink:href", "./thermometer.png")
            .attr('width', 30)
            .attr('height', 28)

        // Create the text that travels along the curve of the chart
        var focusText = focusGroup
            .append('text')
            .attr("text-anchor", "left")
            .attr("alignment-baseline", "middle");

        // Create a rect on top of the svg area: this rectangle recovers mouse position
        d3.select(this)
            .append('rect')
            .style("fill", "none")
            .style("pointer-events", "all")
            .attr('width', trellisWidth)
            .attr('height', trellisHeight)
            .on('mouseover', mouseover)
            .on('mousemove', mousemove)
            .on('mouseout', mouseout);

        // What happens when the mouse move -> show the annotations at the right positions.
        function mouseover() {
            // console.log('Mouseover event');
            focusGroup.style("opacity", 1);
        }
        var bisect = d3.bisector(function (d) { return d.date; }).left;
        function mousemove() {
            // recover coordinate we need
            var x0 = xScale.invert(d3.mouse(this)[0]);
            var i = bisect(filteredData, x0, 1);
            var selectedData = filteredData[i];

            focusCircle
                .attr("x", xScale(selectedData.date))
                .attr("y", yScale(selectedData.actual_mean_temp));

            focusText
                .html("Date: " + d3.timeFormat("%Y-%m-%d")(selectedData.date) + " Actual Mean Temp: " + selectedData.actual_mean_temp + "℉")
                .attr("x", xScale(selectedData.date) + 15)
                .attr("y", yScale(selectedData.actual_mean_temp))
                .style("pointer-events", "none");
        }

        function mouseout() {
            focusGroup.style("opacity", 0);
        }

        d3.select(this)
            .append('g')
            .attr('class', 'x axis')
            .attr('transform', 'translate(0,' + trellisHeight + ')')
            .call(xScaleN)
            .selectAll("text")
            .style("text-anchor", "end")
            .attr("dx", "-.8em")
            .attr("dy", ".15em")
            .attr("transform", "rotate(-45)");

        d3.select(this)
            .append('g')
            .attr('class', 'y axis')
            .call(yScaleN);
    })

    // Small multiple line charts: https://d3-graph-gallery.com/graph/line_smallmultiple.html
    city.append("text")
        .attr("text-anchor", "city-label")
        .attr("y", -5)
        .attr("x", 0)
        .text(function (d) { return (d.key) })
        .style("fill", function (d) { return colorScale(d.key) })

    city.append('text')
        .attr('class', 'x axis-label')
        .attr('x', trellisWidth / 2)
        .attr('y', trellisHeight + 65)
        .text('Date by Month (2014/07/01 - 2015/06/30)')

    city.append('text')
        .attr('class', 'y axis-label')
        .attr('transform', 'rotate(-90)')
        .attr('x', -trellisHeight / 2)
        .attr('y', -30)
        .text('Actual Mean Temp(℉)')
});