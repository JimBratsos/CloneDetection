module Main

import lang::java::m3::AST;
import lang::java::m3::Core;
import List;
import Map;
import IO;
import Location;
import JSONExport;

import NameChange;
import SequenceCalcsV2;
import Util;
import misc::volume;

void main() {
    loc project = |project://testfiles|;
    // loc project = |project://smallsql0.21_src|;
    // loc project = |project://hsqldb-2.3.1|;

    M3 model = createM3FromMavenProject(project);
    int volume = totalCountLinesOfCode(model); // Volume from Series 1 to calculate clone LOC percentage later on

    list[Declaration] asts = getASTs(project); // Change to desired project
    int minSequenceThreshold = 2; // Minimum threshold set for the sequence algorithm

    for(int cloneType <- [1..3]) { // For types 1 and 2
        tuple[map[list[node], lrel[loc,loc]], int, int] cloneLocations = <(),0,0>;

        if (cloneType == 2) asts = changeASTNames(asts);
        cloneLocations = sequenceClones(asts, minSequenceThreshold);

        println("Sequencing finished. Exporting to JSON.");
        println("");

        exportJSON(cloneLocations, project, cloneType, volume); // Export the results in JSON for Visualization

        println("Type " + "<cloneType>" + " finished.");
        println("");
        
        // for(loca <- cloneLocations[0]) {
        //     iprintln(cloneLocations[0][loca]);
        //     iprintln("");
        // }
    }
}