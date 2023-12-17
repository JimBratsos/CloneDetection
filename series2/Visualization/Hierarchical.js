function transformData (jsonData) {
    let correctForm = [];

    jsonData.clone_pairs.forEach(pair => {
        // remove also the .java so I can compare strings and populate imports correctly
        let originFileName = getFullPath(pair.origin.file);
        let cloneFileName = getFullPath(pair.clone.file);
        let randomSize = Math.floor(Math.random() * 1000);

        // console.log(originFileName);
        // console.log(cloneFileName);

        // Add originFileName if not already in correctForm
        if (!correctForm.some(f => f.name === originFileName)) {
            correctForm.push({
                "name": originFileName,
                "size": randomSize,
                "imports": []
            });
        }

        // Add cloneFileName if not already in correctForm
        if (!correctForm.some(f => f.name === cloneFileName)) {
            correctForm.push({
                "name": cloneFileName,
                "size": randomSize,
                "imports": []
            });
        }

        // both must be added to the correctForm.name as a file might only be in the clone_pairs.clone.file and thus 
        // the diagram may not be correctly displayed.

        // Finding the corresponding file object in the flare array
        let fileObj = correctForm.find(f => f.name === originFileName);
        if (fileObj && !fileObj.imports.includes(cloneFileName)) {
            fileObj.imports.push(cloneFileName);
        }
    });

        return correctForm;
}

function getFullPath(path) {
    // Split the path by '/' and get the last element
    let segments = path.replace(/\//g, '.').replace(/^\./, '').replace(/\.java$/, '');
    return segments;
}


function hierarchy(data, delimiter = ".") { // d3 function to correctly format the data
    let root;
    const map = new Map;
    data.forEach(function find(data) {
    const {name} = data;
        
    if (map.has(name)) return map.get(name);
        
        const i = name.lastIndexOf(delimiter);
        
        map.set(name, data);
        
        if (i >= 0) {
            find({name: name.substring(0, i), children: []}).children.push(data);
            data.name = name.substring(i + 1);
            
        } 
        else {
            root = data;
        }
    
        return data;
    });
    
    return root;
}


function visualHierarchical (jsonData) {

    // console.log(jsonData);
    correctForm = transformData(jsonData); // format my json like the flare.json
    data = hierarchy(correctForm); // add parent and child relations to the formatted data
    // console.log(data);

    colorin = "#00f" // blue
    colorout = "#f00" // red
    colornone = "#ccc" // black

    const width = 800;
    const radius = width / 2;

    const tree = d3.cluster()
        .size([2 * Math.PI, radius - 100]);

    const root = tree(bilink(d3.hierarchy(data)
        .sort((a, b) => d3.ascending(a.height, b.height) || d3.ascending(a.data.name, b.data.name))));

    const svg = d3.create("svg")
        .attr("width", width)
        .attr("height", width)
        .attr("viewBox", [-width / 2, -width / 2, width, width])
        .attr("style", "max-width: 100%; height: auto; font: 10px sans-serif;");

    const node = svg.append("g")
        .selectAll()
        .data(root.leaves())
        .join("g")
        .attr("transform", d => `rotate(${d.x * 180 / Math.PI - 90}) translate(${d.y},0)`)
        .append("text")
        .attr("dy", "0.31em")
        .attr("x", d => d.x < Math.PI ? 6 : -6)
        .attr("text-anchor", d => d.x < Math.PI ? "start" : "end")
        .attr("transform", d => d.x >= Math.PI ? "rotate(180)" : null)
        .text(d => d.data.name)
        .each(function(d) { d.text = this; })
        .on("mouseover", overed)
        .on("mouseout", outed)
        .call(text => text.append("title").text(d => `${id(d)}
    ${d.outgoing.length} outgoing
    ${d.incoming.length} incoming`));

    const line = d3.lineRadial()
        .curve(d3.curveBundle.beta(0.85))
        .radius(d => d.y)
        .angle(d => d.x);

    const link = svg.append("g")
        .attr("stroke", colornone)
        .attr("fill", "none")
        .selectAll()
        .data(root.leaves().flatMap(leaf => leaf.outgoing))
        .join("path")
        .style("mix-blend-mode", "multiply")
        .attr("d", ([i, o]) => line(i.path(o)))
        .each(function(d) { d.path = this; });

    function overed(event, d) {

        link.style("mix-blend-mode", null);
        d3.select(this).attr("font-weight", "bold");
        d3.selectAll(d.incoming.map(d => d.path)).attr("stroke", colorin).raise();
        d3.selectAll(d.incoming.map(([d]) => d.text)).attr("fill", colorin).attr("font-weight", "bold");
        d3.selectAll(d.outgoing.map(d => d.path)).attr("stroke", colorout).raise();
        d3.selectAll(d.outgoing.map(([, d]) => d.text)).attr("fill", colorout).attr("font-weight", "bold");

    }

    function outed(event, d) {

        link.style("mix-blend-mode", "multiply");
        d3.select(this).attr("font-weight", null);
        d3.selectAll(d.incoming.map(d => d.path)).attr("stroke", null);
        d3.selectAll(d.incoming.map(([d]) => d.text)).attr("fill", null).attr("font-weight", null);
        d3.selectAll(d.outgoing.map(d => d.path)).attr("stroke", null);
        d3.selectAll(d.outgoing.map(([, d]) => d.text)).attr("fill", null).attr("font-weight", null);
    
    }

    document.getElementById("hierchicalGraph").appendChild(svg.node())

    function bilink(root) {
        const map = new Map(root.leaves().map(d => [id(d), d]));
    
        for (const d of root.leaves()) {
            d.incoming = [];
            d.outgoing = d.data.imports.map(i => {
                const target = map.get(i);
                return target ? [d, target] : null;
            }).filter(Boolean); // Filter out any null entries
        }
        
        for (const d of root.leaves()) {
            for (const o of d.outgoing) {
                if (o[1]) o[1].incoming.push(o);
            }
        }
        
        return root;
    }

    // Generates a unique identifier for each node based on its position in the hierarchy.
    function id(node) {
        return `${node.parent ? id(node.parent) + "." : ""}${node.data.name}`;
    }

}
