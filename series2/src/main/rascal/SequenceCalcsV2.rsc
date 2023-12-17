module SequenceCalcsV2

import List;
import Node;
import Type;
import Set;
import Map;
import IO;
import util::Math;
import lang::java::m3::Core;
import lang::java::m3::AST;
import Location;

import Util;
import NameChange;

// Gets all the sequences like in the paper that have length bigger or equal than the one specified
// list[list[node]] is a list of code blocks as created in the AST
list[list[node]] sequenceExtract(list[Declaration] ast) {
    
    list[list[node]] sequences = [];
    
    visit (ast) {
        case \if(Expression condition, Statement thenBranch, Statement elseBranch) : {
            list[node] wholeIf = [];
            wholeIf += condition;
            wholeIf += thenBranch;
            wholeIf += elseBranch;
            sequences += [wholeIf];
        }
        case list[Statement] sequence: {
            if(size(sequence) != 0) {
                sequences += [sequence];
            }
        }
    }
    
    return sequences;
}

// Gets the length of the biggest sequence
int getLargestSequenceSize(list[list[node]] sequences) {
    if (size(sequences) != 0) {
        return max([size(sequence) | sequence <- sequences]);
    }
    return 0;
}

list[list[node]] getSubSequences(value sequences, int currentK) {
    switch (sequences) {
        case []:
            // Handle empty list
            return [];

        case list[node] sequence: {
            // Handle single list
            if (size(sequence) == currentK) {
                return [sequence]; // Special case when length is equal to the size of the sequence
            }
            if (size(sequence) < currentK) {
                return []; // Return empty list if the sequence is shorter than the specified length
            }
            return [subSequence | i <- [0..size(sequence)], subSequence := sequence[i .. (i + currentK)], size(subSequence) >= currentK]; // Generate subsequences
        }

        case list[list[node]] sequenceList:
            // Handle list of lists
            return concat([getSubSequences(sequence, currentK) | sequence <- sequenceList]);

        default:
            // Handle other types of inputs
            return [];
    }
}

lrel[loc,loc] createPairLocations (list[list[node]] cloneClassList) {
    lrel[loc,loc] pairLocations = [];
    list[loc] locSumL = [];
    list[loc] locSumR = [];

    // for(classElem <- cloneClasses) { // KEY
    list[int] iterateValues = index(cloneClassList); // INDEXES OF list[list[node]]

    for (int i <- iterateValues, int j <- iterateValues) { // TWO DIFFERENT LIST NODES

        locSumL = [];
        locSumR = [];

        if (i >= j) continue; // excludes i == j, and reflexive elements 

        for(listElemI <- cloneClassList[i]) locSumL += listElemI@src; 
        for(listElemJ <- cloneClassList[j]) locSumR += listElemJ@src;
        
        pairLocations += <cover(locSumL), cover(locSumR)>;
    }
        
    // }

    return pairLocations;
}

// Function to compute hash of a sequence
list[node] computeHash(list[node] subSequence) {
    sequenceStr = unsetRec(subSequence);
    return sequenceStr;
}

tuple[map[list[node],list[list[node]]], map[list[node], list[node]]] initializeBuckets(map[list[node],list[list[node]]] buckets, list[list[node]] subsequences, map[list[node], list[node]] cacheDelAnnotations) {

    for (subsequence <- subsequences) {
        list[node] hash = computeHash(subsequence);

        cacheDelAnnotations[subsequence] = hash;

        if (hash in buckets) {
            buckets[hash] += [subsequence];
        } else {
            buckets[hash] = [subsequence];
        }
    }

    return <buckets, cacheDelAnnotations>;
}

tuple[map[list[node], lrel[loc,loc]], int, int] sequenceClones(list[Declaration] asts, int minSequenceThreshold, int cloneType) {
    real similarityThreshold = -1.0;
    map[list[node], list[list[node]]] cloneClasses = ();
    map[list[node], lrel[loc,loc]] cloneClassesPairs = ();
    map[list[node],int] subFreq = ();

    list[list[node]] sequences = sequenceExtract(asts);

    int maximumSequenceLength = getLargestSequenceSize(sequences);

    list[int] k = [minSequenceThreshold.. (maximumSequenceLength + 1)];

    // println(k);

    for (everyK <- k) {

        map[list[node], list[node]] cacheDelAnnotations = ();
            
        // println("k ATM: " + "<everyK>");
        
        list[list[node]] subsequences = getSubSequences(sequences, everyK);
        
        map[list[node],list[list[node]]] buckets = (); 
        tuple[map[list[node],list[list[node]]], map[list[node], list[node]]] initializeValues = initializeBuckets(buckets, subsequences, cacheDelAnnotations);
        buckets = initializeValues[0];
        cacheDelAnnotations = initializeValues[1];

        // println("BUCKET SIZE: " + "<size(buckets)>");
        // int bucketNow = 0;

        for (hash <- buckets) {

            // bucketNow += 1; // BUCKET PROGRESS DEBUG
            // println("BUCKET ATM: " + "<bucketNow>" + " SIZED: " + "<size(buckets[hash])>");

            if (size(buckets[hash]) > 1) {
                list[list[node]] currentBucket = buckets[hash];

                if(currentBucket[0] notin cacheDelAnnotations) {
                    cacheDelAnnotations[currentBucket[0]] = unsetRec(currentBucket[0]);
                }

                list[node] keyNode = cacheDelAnnotations[currentBucket[0]];

                cloneClasses = subsumeRemoveFinal(cloneClasses, currentBucket, cloneType);
                cloneClasses[keyNode] = currentBucket;
            }
        }
    }

    println("Finished Capturing Classes. Class Number: " + "<size(cloneClasses)>");

    int maxClassMembers = 0;
    int maxClassLines = 0;

    for(class <- cloneClasses) {
        int classSize = 0;
        if(class notin cloneClassesPairs) {
            cloneClassesPairs[class] = [];
        }
        // println("CLASS ELEMENTS- SIZE: " + "<size(cloneClasses[class])>" + " OF ELEMENT SIZE: " + "<size(class)>");
        // list[loc] tempLoc = [];
        // for(elem <- cloneClasses[class][0]) tempLoc += elem@src;
        // println("ELEMENT OF TYPE: " + "<cover(tempLoc)>");

        cloneClassesPairs[class] += createPairLocations(cloneClasses[class]);
        if (maxClassMembers <= size(cloneClasses[class])) maxClassMembers = size(cloneClasses[class]);
        if (maxClassLines <= size(class)) maxClassLines = size(class);
    }

    println("Max Class in Members: " + "<maxClassMembers>");
    println("Max Class in Lines: " + "<maxClassLines>");
    
    return <cloneClassesPairs, maxClassMembers, maxClassLines>;
}