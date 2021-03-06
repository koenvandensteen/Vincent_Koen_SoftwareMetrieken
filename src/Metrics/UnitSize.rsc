module Metrics::UnitSize

import IO;
import util::Resources;
import List;
import Set;
import util::Resources;
import lang::java::m3::AST;
import util::Math;
import analysis::statistics::Descriptive;
import lang::java::jdt::m3::Core;
import String;
import Relation;
import Map;

import Helpers::HelperFunctions;

/*
/	main method of this metric, returns a map with locations per method and their respective size
*/
public map [loc, int] AnalyzeUnitSize(set[Declaration] decls)
{
	map[loc, int] unitSize = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add lines of code to the executable methods
			case m: \method(_, _, _, _,Statement impl): {
				unitSize += (m.src:getUnitSize(impl));
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case m: \constructor(_, _, _, Statement impl): {
				unitSize += (m.src:getUnitSize(impl));
			}
		}
	}
	return unitSize;
}

private int getUnitSize(Statement s){
	list[str] filteredFile = FilterSingleFile(s.src);
	return size(filteredFile);
}