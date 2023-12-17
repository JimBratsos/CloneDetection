function populateCloneSelect(jsonData) {
    // console.log(jsonData);

    const cloneSelect = document.getElementById('cloneSelect');

    jsonData.clone_pairs.forEach(function(clonePair, index) {
        var option = document.createElement('option');
        option.value = clonePair.id;
        option.textContent = 'Clone Pair ' + (index + 1);
        // console.log(option.textContent);
        cloneSelect.appendChild(option);
    });   
}

function displayClonePairCode(cloneId, jsonData) {
    
    var clonePair = jsonData.clone_pairs.find(pair => pair.id === cloneId);
    
    if (clonePair) {
        document.getElementById('originalCode').innerHTML = clonePair.origin.source_code;
        document.getElementById('cloneCode').innerHTML = clonePair.clone.source_code;
    }
}


