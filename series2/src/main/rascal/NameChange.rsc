module NameChange

import lang::java::m3::AST;
import lang::java::m3::Core;

str SIMILAR_ID = "ID";
// str SIMILAR_STR = "STR";
// str SIMILAR_NUM = "0";
// bool SIMILAR_BOOL = true;

list[Declaration] changeASTNames(list[Declaration] asts) {

    // remove literals and identifiers to make it dump
    return visit(asts) {
    
        // remove identifiers        
        case \simpleName(_) => \simpleName(SIMILAR_ID)
        case \class(_, a, b, c) => \class(SIMILAR_ID, a, b, c)

        case \method(Type returnType, _, list[Declaration] parameters, list[Expression] exceptions, Statement body) 
        => \method(Type::\void(), SIMILAR_ID, parameters, exceptions, body)
        
        case \constructor(_, a, b, c) => \constructor(SIMILAR_ID, a, b, c)
        case \parameter(a, _, b) => \parameter(a, SIMILAR_ID, b)
        case \variable(_, a) => \variable(SIMILAR_ID, a)
        case \variable(_, a, b) => \variable(SIMILAR_ID, a, b)
        case \label(_, body) => \label(SIMILAR_ID, body)
        case \enum(_, a, b, c) => \enum(SIMILAR_ID, a, b, c)
        case \import(_) => \import(SIMILAR_ID)
        case \typeParameter(_, list[Type] a) => \typeParameter(SIMILAR_ID, a)
        case \annotationType(_, a) => \annotationType(SIMILAR_ID, a)
        case \annotationTypeMember(a, _) => \annotationTypeMember(a, SIMILAR_ID)
        case \annotationTypeMember(a, _, b) => \annotationTypeMember(a, SIMILAR_ID, b)
        case \vararg(a, _) => \vararg(a, SIMILAR_ID)
        
        // calls
        case \fieldAccess(a, b, _) => \fieldAccess(a, b, SIMILAR_ID)
        case \fieldAccess(a, _) => \fieldAccess(a, SIMILAR_ID)
        case \methodCall(a, _, b) => \methodCall(a, SIMILAR_ID, b)
        case \methodCall(a, b, _, c) => \methodCall(a, b, SIMILAR_ID, c)
    }
}