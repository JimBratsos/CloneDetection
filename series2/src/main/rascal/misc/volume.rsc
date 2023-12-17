module misc::volume

import lang::java::m3::AST;
import lang::java::m3::Core;
import String;
import List;
import IO;

set[loc] getFiles(M3 model) {
    return { location | < location, _ > <- model@declarations, isCompilationUnit(location)}; 
    // gets compilation units (files) from the declarations field of an M3 model
}

list[str] filterList(list[str] input) {

    bool finder = false; // when false im not in a comment
    int commentCounter = 0;
    list[str] newList = [];

    // int length = size(input); // length variable stores the size of the table calculated in the getLocationLines function

    for (str elem <- input) {
        commentCounter += 1;

        switch (elem) {

            case /( *\*\/)( )*( *\/\*)(.)*(\*\/)/: {
                finder = false;
                continue;
                // for comments such as */ /* */
            }

            case /( *\*\/)( )*( *\/\/)(.)*/: {
                finder = false;
                continue;
                 // regex for comments as such */ //. The spaces between the two comments can be either one or more.
            }

            case /( *\*\/)( )*( *\/\*)(.)*/: {
                finder = true;
                continue; // for comments such as */ /* without the */ being in the same line
            }
            
            case /^\s*$/ : {
                continue; // for empty lines
            }

            case /( *\/\/)(.)*/: {
                continue; // for // comments
            }

            case /( *\/\*)(.)*(\*\/)/: continue; // for /* */ comments in the same line

            case /( *\/\*)(.)*/: {
                finder = true;
                commentCounter = 1; // if you find /* and you do not have */ in the same line
            }

            case /^\s*\*\/$/: { 
                finder = false; // regex for comments as such */
            }

            case /( *\*\/)(.)*/: {
                newList += elem;
                finder = false; // regex for comments as such */ ... 
            }

            default: {
                if (finder == false) {
                    newList += elem;
                }
            }
            
        }
    }
    return newList;
}

list[str] getLocationLines(loc location) {
    return [trim(line) | line <- split("\n", readFile(location))];
}

// counts LOC for one file
int countLinesOfCode(loc location) {
    return size(filterList(getLocationLines(location)));
}

// counts LOC for all the project (VOLUME)
int totalCountLinesOfCode(M3 model) {
    return sum([countLinesOfCode(file) | file <- getFiles(model)]);
}