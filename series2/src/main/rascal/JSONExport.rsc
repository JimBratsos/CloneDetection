module JSONExport

import lang::json::IO;
import Location;
import String;
import IO;
import Map;
import util::Math;
import List;

list[str] getDirectories(loc mainDirectory) { // Stop the recursion
    return getDirectories(mainDirectory, false); 
}

list[str] getDirectories(loc mainDirectory, bool recursive) { // Recursively get all the directories
    list[str] directories = [];

    if (exists(mainDirectory) && isDirectory(mainDirectory)) {
        list[loc] entries = mainDirectory.ls;
        
        for (loc entryLoc <- entries) {
            if (isDirectory(entryLoc)) {
                // Add just the directory name, not the full URI
                directories += [entryLoc.path];
                
                // If recursive is true, recurse into the subdirectory
                if (recursive) {
                    // Concatenate the current directory name with the result of the recursive call
                    directories += getDirectories(entryLoc, true); // Recursive call
                }
            }
        }
    } else {
        println("Directory does not exist or is not accessible");
    }

    return directories;
}

list[map[str, value]] getFileDetails(loc mainDirectory) {
    list[map[str, value]] files = [];

    if (exists(mainDirectory) && isDirectory(mainDirectory)) {
        list[loc] entries = mainDirectory.ls; // This should list all entries in the directory

        for (loc entryLoc <- entries) {
            if (isDirectory(entryLoc)) {
                // Recurse into the subdirectory
                files += getFileDetails(entryLoc);
            } else if (contains(entryLoc.path, ".java")) {
                // It's a Java file, add its details to the list
                map[str, value] fileDetails = ("name": entryLoc.path, "dir": entryLoc.parent);
                files += [fileDetails];
            }
        }
    } else {
        println("Directory does not exist or is not accessible");
    }

    return files;
}

tuple[str,map[loc,str]] getSourceCode(loc location, map[loc,str] cacheContent) {
    if (location notin cacheContent) {
        cacheContent[location] = getContent(location);
    }

    return <cacheContent[location], cacheContent>;
}

tuple[list[map[str, value]],int] createClonePairsJSON(map[list[node], lrel[loc, loc]] cloneLocations, int cloneType) {

    str cloneTypeStr = "";
    int totalSize = 0;
    map[loc,str] cacheContent = ();
    list[map[str, value]] clonePairs = [];
    set[loc] pairChecked = {};

    int cloneID = 1;

    if (cloneType == 1) {
        cloneTypeStr = "type-1";
    } else {
        cloneTypeStr = "type-2";
    }

    for (list[node] class <- cloneLocations) {
        lrel[loc, loc] locations = cloneLocations[class];

        for (tuple[loc,loc] locTuple <- locations) {
            loc originLoc = locTuple[0];
            loc cloneLoc = locTuple[1];

            tuple[str,map[loc,str]] originLocMap = getSourceCode(originLoc, cacheContent);
            cacheContent = originLocMap[1];
            tuple[str,map[loc,str]] cloneLocMap = getSourceCode(originLoc, cacheContent);
            cacheContent = cloneLocMap[1];
            
            map[str, value] clonePair = (
                "id": "clone_" + "<cloneID>",
                "clone_type": cloneTypeStr, // Adjust as per your clone classification logic
                "origin": (
                    "file": originLoc.path, // Access file path
                    "start_line": originLoc.begin.line, // Access start line
                    "end_line": originLoc.end.line, // Access end line
                    "source_code": originLocMap[0] // You need to define this function
                ),
                "clone": (
                    "file": cloneLoc.path,
                    "start_line": cloneLoc.begin.line,
                    "end_line": cloneLoc.end.line,
                    "source_code": cloneLocMap[0] // You need to define this function
                )
            );

            clonePairs = clonePairs + [clonePair];
            cloneID += 1;
            if(originLoc notin pairChecked) totalSize += ((originLoc.end.line - originLoc.begin.line) + 1);
            if(cloneLoc notin pairChecked) totalSize += ((cloneLoc.end.line - cloneLoc.begin.line) + 1);
            
            pairChecked = pairChecked + originLoc;
            pairChecked = pairChecked + cloneLoc;
        }
    }

    return <clonePairs, totalSize>;
}

void exportJSON(tuple[map[list[node], lrel[loc,loc]], int, int] cloneLocations, loc mainDir, int cloneType, int volume) {
    map[str, str] summary = ("project_name": "Project");
    list[str] directories = getDirectories(mainDir, true);
    list[map[str, value]] files = getFileDetails(mainDir);

    tuple[list[map[str, value]], int] clonePairsAndSize = createClonePairsJSON(cloneLocations[0], cloneType);
    list[map[str, value]] clonePairs = clonePairsAndSize[0];
    int totalSize = clonePairsAndSize[1];
    real clonePercentage = (toReal(totalSize) / toReal(volume)) * 100;

    map[str, value] jsonStructure = (
        "summary": summary,
        "directories": directories,
        "files": files,
        "clone_pairs": clonePairs,
        "clone_class_num": size(cloneLocations[0]),
        "biggest_class_members": cloneLocations[1],
        "biggest_class_lines": cloneLocations[2],
        "total_clone_size": totalSize,
        "clone_code_percentage": clonePercentage,
        "volume": volume
    );

    if(cloneType == 1) {
        writeJSON(|project://series2/Visualization/<mainDir.authority>/results1.json|, jsonStructure, indent = 2);
    } else {
        writeJSON(|project://series2/Visualization/<mainDir.authority>/results2.json|, jsonStructure, indent = 2);
    }

}