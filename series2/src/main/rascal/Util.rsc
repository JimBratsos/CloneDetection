module Util

import IO;
import Set;
import Map;
import lang::java::m3::AST;
import lang::java::m3::Core;
import List;
import String;
import Location;

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation); // Returns AST of a directory
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

map[list[node], list[list[node]]] subsumeRemoveFinal(map[list[node], list[list[node]]] cloneList, list[list[node]] parent, int cloneType) {
    list[list[node]] toDelete = [];

    for(child <- cloneList) {
        if(size(child) == size(parent[0])) continue;

        if(isSubsumed(parent, cloneList[child])) {
            toDelete += [child];
        }
    }

    for (child <- toDelete) {
        cloneList = delete(cloneList, child);
    }

    return cloneList;
}

bool isParent(list[node] parent, list[node] child) {

    int childrenFound = 0;
    node toFindNodeStart = child[0];
    node toFindNodeEnd = last(child);

    visit(parent) {
        case node parentNode: {
            if (parentNode == toFindNodeStart || parentNode == toFindNodeEnd) {
                childrenFound += 1;
                if (childrenFound == 2) return true;
            }
        }   
    }

    return false;
}

bool isSubsumed(list[list[node]] parent, list[list[node]] child) {
    for (childSeq <- child) {
        bool found = any(parentSeq <- parent, isParent(parentSeq, childSeq));
        if (!found) {
            return false;
        }
    }
    return true;
}

///////////////////////////////////FOR LEGACY PURPOSES FOR BASIC ALGO/////////////////////////////////////////////

// bool checkChild(node nodeElem, node cloneClassNode) {
//     visit(nodeElem) {
//         case node child: {
//             if (child == cloneClassNode) {
//                 return true;
//             }
//         }
//     }

//     return false;
// }

// map[int,list[node]] subsumeRemove(map[int,list[node]] cloneClasses, list[tuple[int,int]] classMass) {
//     for(tuple[int,int] massIndex <- classMass) {
//         if (massIndex[1] in cloneClasses) {
//             list[node] nodeList = cloneClasses[massIndex[1]]; // Get the list of all the nodes (from the tuple)
//             node nodeElem = delAnnotationsRec(nodeList[0]); // Pick the first (random) node from the class 
            
//             for (int key <- cloneClasses) { // iterate through all the classes to find duplicate clones
//                 if(key != massIndex[1]) { // make sure I check other classes and not the class with itself
//                     if( checkChild(nodeElem, delAnnotationsRec(cloneClasses[key][0])) && (size(nodeList) == size(cloneClasses[key])) ) {
//                         // compare the first class with all the other and make sure that the child list deleted is of the same size. 
//                         // If not then the child list should not be deleted as they may be smaller clones in other places.
//                         cloneClasses = delete(cloneClasses, key);
//                     }
//                 }
//             }
//         }
//     }

//     return cloneClasses;
// }

// set[node] getNodes(list[node] tree) {
//     set[node] treeNodes = {};
    
//     visit (tree) {
//         case Statement n: treeNodes += n;
//         case Declaration n: treeNodes += n;
//     }
    
//     return treeNodes;
// }

// int calculateMass(list[node] subtree) {
//     int mass = 0;
//     visit(subtree) {
//         case node nodes: {
//             mass += 1;
//         }
//     }
//     return mass;
// }

// int calculateMass(node subtree) {
//     int mass = 0;
//     visit(subtree) {
//         case node nodes: {
//             mass += 1;
//         }
//     }
//     return mass;
// }