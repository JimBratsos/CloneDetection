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


function visualTidyTree (jsonData) {

    // console.log(jsonData);
    correctForm = transformData(jsonData); // format my json like the flare.json
    data = hierarchy(correctForm); // add parent and child relations to the formatted data
    // console.log(data);

    const width = 928;

    // Compute the tree height; this approach will allow the height of the
    // SVG to scale according to the breadth (width) of the tree layout.
    const root = d3.hierarchy(data);
    const dx = 10;
    const dy = width / (root.height + 1);
  
    // Create a tree layout.
    const tree = d3.tree().nodeSize([dx, dy]);
  
    // Sort the tree and apply the layout.
    root.sort((a, b) => d3.ascending(a.data.name, b.data.name));
    tree(root);
  
    // Compute the extent of the tree. Note that x and y are swapped here
    // because in the tree layout, x is the breadth, but when displayed, the
    // tree extends right rather than down.
    let x0 = Infinity;
    let x1 = -x0;
    root.each(d => {
      if (d.x > x1) x1 = d.x;
      if (d.x < x0) x0 = d.x;
    });
  
    // Compute the adjusted height of the tree.
    const height = x1 - x0 + dx * 2;
  
    const svg = d3.create("svg")
        .attr("width", width)
        .attr("height", height)
        .attr("viewBox", [-dy / 3, x0 - dx, width, height])
        .attr("style", "max-width: 100%; height: auto; font: 10px sans-serif;");
  
    const link = svg.append("g")
        .attr("fill", "none")
        .attr("stroke", "#555")
        .attr("stroke-opacity", 0.4)
        .attr("stroke-width", 1.5)
      .selectAll()
        .data(root.links())
        .join("path")
          .attr("d", d3.linkHorizontal()
              .x(d => d.y)
              .y(d => d.x));
    
    const node = svg.append("g")
        .attr("stroke-linejoin", "round")
        .attr("stroke-width", 3)
      .selectAll()
      .data(root.descendants())
      .join("g")
        .attr("transform", d => `translate(${d.y},${d.x})`);
  
    node.append("circle")
        .attr("fill", d => d.children ? "#555" : "#999")
        .attr("r", 2.5);
  
    node.append("text")
        .attr("dy", "0.31em")
        .attr("x", d => d.children ? -6 : 6)
        .attr("text-anchor", d => d.children ? "end" : "start")
        .text(d => d.data.name)
      .clone(true).lower()
        .attr("stroke", "white");
    
    // return svg.node();
    document.getElementById("tidyTree").appendChild(svg.node())

}