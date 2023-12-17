function populateMetrics(jsonData) {

    document.getElementById('clonedPercentage').innerHTML = jsonData.clone_code_percentage;
    document.getElementById('biggestClassMembers').innerHTML = jsonData.biggest_class_members;
    document.getElementById('biggestClassLines').innerHTML = jsonData.biggest_class_lines;
    document.getElementById('totalCloneSize').innerHTML = jsonData.total_clone_size;
}