module BasicAlgo

import IO;
import Set;
import Node;
import Map;
import lang::java::m3::AST;
import lang::java::m3::Core;
import util::Math;
import List;

import Util;
import NameChange;

node similarityCalc(real similarityThreshold, node nodeToCheck, map[node, list[node]] nodes) {
    real similarity = 0.0;
    real similarityBefore = 0.0;

    if(similarityThreshold == 1) {
        if(nodeToCheck in nodes) {
            nodeToReturn = nodeToCheck;
            return nodeToReturn;
        } else {
            return "src"("empty");
        }
    } else {
        for(node nodeInMap <- nodes) {
            int massTreeMap = calculateMass(nodeInMap); // Get the mass of the node checked from map
            int massTreeCheck = calculateMass(nodeToCheck); // Get the mass of the node to check now

            set[node] nodesTreeMap = getNodes(nodeInMap); // Get all the nodes from the map node that is checked atm
            set[node] nodesTreeCheck = getNodes(nodeToCheck); // Get all the nodes from the node that is checked at the moment

            set[node] shared = { tree1 | tree1 <- nodesTreeMap, tree2 <- nodesTreeCheck, tree1 == tree2};

            S = size(shared);
            L = massTreeMap - S;
            R = massTreeCheck - S;

            // println("S = " + "<S>" + " R = " + "<R>" + " L = " + "<L>");
            // println("");
            
            real similarity = toReal(2 * S) / toReal((2 * S) + L + R);
            
            if(similarityBefore <= similarity) {
                nodeToReturn = nodeInMap;
                similarityBefore = similarity;
            }
        }
        
        if (similarityBefore >= similarityThreshold) {
            return nodeToReturn;
        }

        nodeToReturn = "src"("empty");
        return nodeToReturn;
    }
}

map[int,list[node]] basicAlgo(list[Declaration] asts, int cloneType, int massThreshold) {

    map[int,list[node]] cloneClasses = (); // List of types of clones already detected just so we can identify child/parent relations
    map[node, list[node]] nodes = (); // node without location / node with location
    list[tuple[int,int]] classMass = []; // Mass of each element in class and its id
    int classNum = 1; // Number of classes we have
    
    real similarityThreshold = 0.0;

    if (cloneType == 1) {
		similarityThreshold = 1.0;
	} else if(cloneType == 2) {
		similarityThreshold = 1.0;
        asts = changeASTNames(asts);
	} else if(cloneType == 3) {
		similarityThreshold = 0.80;
	}

    visit(asts) {
        case node subtree: {

            if (calculateMass(subtree) >= massThreshold) {

                node nodeWithoutLoc = delAnnotationsRec(subtree); // node without location
                
                node returned = similarityCalc(similarityThreshold, nodeWithoutLoc, nodes);

                if (returned != "src"("empty")) {
                    nodeWithoutLoc = returned;
                    // Buckets with values as subtrees. If already exist add a new value.
                    nodes[nodeWithoutLoc] += [subtree];

                } else {
                    // Else create a new bucket that has the node content excluding the location.
                    nodes[nodeWithoutLoc] = [subtree];
                }

            }
            
        }
    }  

    for (node key <- nodes) {
        list[node] subTrees = nodes[key]; // List of subtrees with locations
        if (size(subTrees) > 1) { // if size > 1 then clones exist
        // create a classMass containing clones of the same type
            classMass += <-calculateMass(subTrees[0]),classNum>; // multiple by -1 to sort in descending order
            cloneClasses[classNum] = subTrees;
            classNum += 1;
        }
    }

    classMass = sort(classMass); // sort 

    cloneClasses = subsumeRemove(cloneClasses, classMass); // Remove subsumed classes

    println("CLONE CLASSES: " + "<size(cloneClasses)>");

    for(int key <- cloneClasses) {
        iprintln("<getKeywordParameters(cloneClasses[key][0])>");
        iprintln("<cloneClasses[key][0]>");
        println("");
    }
    
    return cloneClasses;
}

void run() {
    int massThreshold = 6; // Minimum mass of nodes
    // list[Declaration] asts = getASTs(|project://smallsql0.21_src|);
    list[Declaration] asts = getASTs(|project://testfiles|);
    // list[Declaration] asts = getASTs(|project://hsqldb-2.3.1|);

    int cloneType = 2; // Type of clone to detect

    // Run the basic algorithm
    // map[int,list[node]] clones = basicAlgo(asts, cloneType, massThreshold);
}