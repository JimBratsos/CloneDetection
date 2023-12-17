module JSONExport

import lang::json::IO;
import Location;
import misc::volume;
import String;
import IO;
import Map;
import Set;
import util::Math;
import List;

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
    map[str, set[int]] fileExists = ();

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
                "clone_type": cloneTypeStr,
                "origin": (
                    "file": originLoc.path, 
                    "start_line": originLoc.begin.line,
                    "end_line": originLoc.end.line,
                    "source_code": originLocMap[0]
                ),
                "clone": (
                    "file": cloneLoc.path,
                    "start_line": cloneLoc.begin.line,
                    "end_line": cloneLoc.end.line,
                    "source_code": cloneLocMap[0]
                )
            );

            clonePairs = clonePairs + [clonePair];
            cloneID += 1;
            if(originLoc.uri in fileExists) {
                set[int] locSet = toSet([originLoc.begin.line..originLoc.end.line]);
                fileExists[originLoc.uri] = fileExists[originLoc.uri] + locSet;
            } else {
                set[int] locSet = toSet([originLoc.begin.line..originLoc.end.line]);
                fileExists[originLoc.uri] = locSet;
            }

            if(cloneLoc.uri in fileExists) {
                set[int] locSet = toSet([cloneLoc.begin.line..cloneLoc.end.line]);
                fileExists[cloneLoc.uri] = fileExists[cloneLoc.uri] + locSet;
            } else {
                set[int] locSet = toSet([cloneLoc.begin.line..cloneLoc.end.line]);
                fileExists[cloneLoc.uri] = locSet;
            }
        }
    }

    for(fileLoc <- fileExists) {
        totalSize += size(fileExists[fileLoc]);
    }

    return <clonePairs, totalSize>;
}

void exportJSON(tuple[map[list[node], lrel[loc,loc]], int, int] cloneLocations, loc mainDir, int cloneType, int volume) {
    map[str, str] summary = ("project_name": "Project");

    tuple[list[map[str, value]], int] clonePairsAndSize = createClonePairsJSON(cloneLocations[0], cloneType);
    list[map[str, value]] clonePairs = clonePairsAndSize[0];
    int totalSize = clonePairsAndSize[1];
    real clonePercentage = (toReal(totalSize) / toReal(volume)) * 100;

    map[str, value] jsonStructure = (
        "summary": summary,
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