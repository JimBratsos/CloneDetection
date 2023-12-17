function processCloneData(jsonData1, jsonData2) {
    let total1 = 0;
    let total2 = 0;

    var [cloneTypeCounts1,totalType1Frequencies,totalType2Frequencies] = readJson(jsonData1, total1, total2);

    // use the returned vars for freq so that they are updated correctly
    var [cloneTypeCounts2,totalType1Frequencies,totalType2Frequencies] = readJson(jsonData2, totalType1Frequencies, totalType2Frequencies);
    var totalCLones = totalType1Frequencies + totalType2Frequencies; // divide by the total amount of clones

    // format data for D3 function
    let dataArray = [];
    for (let type in cloneTypeCounts1) {
        dataArray.push({ clone_type: type, frequency: cloneTypeCounts1[type]/totalCLones });
    }
    for (let type in cloneTypeCounts2) {
        dataArray.push({ clone_type: type, frequency: cloneTypeCounts2[type]/totalCLones });
    }

    document.getElementById('totalClones1').innerHTML = totalType1Frequencies;
    document.getElementById('totalClones2').innerHTML = totalType2Frequencies;

    return dataArray;
}

function readJson (jsonData, totalType1Frequencies, totalType2Frequencies) {

    let cloneTypeCounts = {}; // add the clones depending on their type

    // Iterate over the clone_pairs array
    jsonData.clone_pairs.forEach(clonePair => {
        let cloneType = clonePair.clone_type; // type-1 or type-2
        
        // Increment the total frequencies based on clone type
        if (cloneType === "type-1") {
            totalType1Frequencies++;
        } else if (cloneType === "type-2") {
            totalType2Frequencies++;
        }

        // If the clone type is already in the object, increment its count
        if (cloneType in cloneTypeCounts) {
            cloneTypeCounts[cloneType]++;
        } else {
            // Otherwise, add the clone type to the object with a count of 1
            cloneTypeCounts[cloneType] = 1;
        }
    });

    return [cloneTypeCounts,totalType1Frequencies,totalType2Frequencies];
}

function visualBarChart (firstJson, secondJson) {

    data = processCloneData(firstJson, secondJson);

    // Declare the chart dimensions and margins.
    const width = 928;
    const height = 500;
    const marginTop = 30;
    const marginRight = 0;
    const marginBottom = 30;
    const marginLeft = 40;

    // Declare the x (horizontal position) scale.
    const x = d3.scaleBand()
        .domain(d3.groupSort(data, ([d]) => -d.frequency, (d) => d.clone_type)) // descending frequency
        .range([marginLeft, width - marginRight])
        .padding(0.1);

    // Declare the y (vertical position) scale.
    const y = d3.scaleLinear()
        .domain([0, 1])
        .range([height - marginBottom, marginTop]);

    // Create the SVG container.
    const svg = d3.create("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", [0, 0, width, height])
        .attr("style", "max-width: 100%; height: auto;");

    // Add a rect for each bar.
    svg.append("g")
        .attr("fill", "steelblue")
    .selectAll()
    .data(data)
    .join("rect")
        .attr("x", (d) => x(d.clone_type))
        .attr("y", (d) => y(d.frequency))
        .attr("height", (d) => y(0) - y(d.frequency))
        .attr("width", x.bandwidth());

    // Add the x-axis and label.
    svg.append("g")
        .attr("transform", `translate(0,${height - marginBottom})`)
        .call(d3.axisBottom(x).tickSizeOuter(0));

    // Add the y-axis and label, and remove the domain line.
    svg.append("g")
        .attr("transform", `translate(${marginLeft},0)`)
        .call(d3.axisLeft(y).tickFormat((y) => (y * 100).toFixed()))
        .call(g => g.select(".domain").remove())
        .call(g => g.append("text")
            .attr("x", -marginLeft)
            .attr("y", 10)
            .attr("fill", "currentColor")
            .attr("text-anchor", "start")
            .text("↑ Frequency (%)"));

    document.getElementById("barChart").appendChild(svg.node())

}