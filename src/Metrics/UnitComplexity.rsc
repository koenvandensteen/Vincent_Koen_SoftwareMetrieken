module Metrics::UnitComplexity

import IO;
import List;
import Map;
import Relation;
import Set;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import util::Math;

import Helpers::HelperFunctions;

import Metrics::UnitSizeAlt;

/*
/	main method of this metric, returns a map with locations per method and their respective complexity
*/
public map [loc, int] AnalyzeUnitComplexity(set[Declaration] decls)
{
	map[loc, int] cyclicComplexity = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add complexity
			case m: \method(_, _, _, _, Statement impl): {
				cyclicComplexity += (m.src:getCyclicComplexityMethod(impl));
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case m: \constructor(_, _, _, Statement impl): {
				cyclicComplexity += (m.src:getCyclicComplexityMethod(impl));
			}
		}
	}
	return cyclicComplexity;
}

// for each method check the complexity
private int getCyclicComplexityMethod(Statement s){

	// programmable: should exception handling be counted -> int = 1; if not int = 0;
	int countExceptions = 1;
	
	// base complexity = 1 for each started method
	int complexity = 1;
	
	// For each of the following in the Statment (method) add one for complexity
	// based on list at http://tutor.rascal-mpl.org/Rascal/Declarations/Function/Function.html#/Rascal/Libraries/lang/java/m3/AST/Declaration/Declaration.html
	// filtered in order to only keep the "choices"
	visit(s){
		// add one complexity point for each itterative structure		
		case \do(_, _): {
			complexity += 1;
		}
		case \foreach(_, _, _): {
			complexity += 1;
		}
		case \for(_, _, _, _): {
			complexity += 1;
		} 
		case \for(_, _, _): {
			complexity += 1;
		}
		case \while(_, _): {
			complexity += 1;
		}
		// add one complexity point for each additional construct
		case \if(_, _): {
			complexity += 1;
		}
		case \if(_, _, _): {
			complexity += 1;
		}
		// add one complexity for booleans
		case \infix(_,"&&",_): {
			complexity += 1;
		}
		case \infix(_,"||",_): {
			complexity += 1;
		}	
		// add one complexity point for each case or default block a switch statement
		case \case(_): {
			complexity += 1;
		}
		// the default case does not add to the cyclomatic complexity
		// add one complexity for each decision related to error handling
		case \throw(_): {
			complexity += countExceptions;
		}
		case \try(_, _): {
			complexity += countExceptions;
		}
		case \try(_, _, _): {
			complexity += countExceptions;
		}
		// find conditionals using the [ expr ? a : b ] structure
		case \conditional(_,_,_): {
			complexity += 1;
		}		
	}
	return complexity;
}