var directoryFiles = {}

document.getElementById('folderSelect').addEventListener('change', function() {

    var folder = this.value;
    var fileSelect = document.getElementById('fileSelect');
    var files;

    switch (folder) {
        case 'none':
            break;
        case 'testfiles':
            files = ['results1.json', 'results2.json'];
            break;
        case 'small':
            files = ['smallsql1.json', 'smallsql2.json'];
            break;
        case 'hsq':
            files = ['resultshsql.json', 'file6.json'];
            break;
        default:
            files = []; // Empty or default case
    }

     directoryFiles[folder] = files;

    // Clear existing options in fileSelect
    fileSelect.innerHTML = '<option value="" disabled selected>Select a file</option>';

    // Populate the file select element
    files.forEach(function(file) {
        var option = document.createElement('option');
        option.value = file;
        option.textContent = file;
        fileSelect.appendChild(option);
    });

});

document.getElementById('fileSelect').addEventListener('change', function() {
    
    var folder = document.getElementById('folderSelect').value;
    var selectedFile = this.value;

    // construct the path in order to get the specified data
    var path = folder + '/' + selectedFile; // used for zoomable circle packing and hierarchical edge bundling

    document.getElementById('cloneSelect').innerHTML = "";

    loadTheCorrectJson(path);

});

function setupCloneSelectListener(jsonData) {
    displayClonePairCode(document.getElementById('cloneSelect').value, jsonData); // when choosing a file display the 1st option

    document.getElementById('cloneSelect').addEventListener('change', function(e) {
        var selectedCloneId = e.target.value;
        displayClonePairCode(selectedCloneId, jsonData);
    });
}


function loadTheCorrectJson(selectedPath) {

    var directory = selectedPath.split('/')[0];
    var firstFile = selectedPath.split('/')[1];

    var filesInDirectory = directoryFiles[directory];

    var secondFile = filesInDirectory.find(file => file !== firstFile);
    var secondFilePath = directory + '/' + secondFile;

    Promise.all([fetch(selectedPath), fetch(secondFilePath)])
        .then(responses => Promise.all(responses.map(response => response.json())))

    // fetch(selectedPath, secondFile)
    //     .then(response => response.json())
        .then(jsonData => {
            resetCharts();
            
            // for the array displaying the code duplications
            populateCloneSelect(jsonData[0]);
            setupCloneSelectListener(jsonData[0]);

            visualBarChart(jsonData[0], jsonData[1]);
            visualCirclePacking(jsonData[0]);
            visualHierarchical(jsonData[0]);
            
        })
        .catch(error => console.error('Error loading JSON:', error));
}

// resets the previously created chart so that only one appears and not multiple
function resetCharts() {
    const bar = document.getElementById('barChart');
    const circles = document.getElementById('kyklous');
    const hierarchy = document.getElementById('hierchicalGraph');
    while (bar.firstChild) {
        bar.removeChild(bar.firstChild);
    }
    while (circles.firstChild) {
        circles.removeChild(circles.firstChild);
    }
    while (hierarchy.firstChild) {
        hierarchy.removeChild(hierarchy.firstChild);
    }
}
