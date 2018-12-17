module Metrics::UnitSizeAlt

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import analysis::statistics::Descriptive;
import util::Math;

import Helpers::HelperFunctions;


public void TestAnalyzeUnitSize()
{
	loc project = |project://SimpleJavaDemo|;	
	// prepare AST
	set[loc] files = getFilesJava(project);
	set[Declaration] ASTDeclarations = createAstsFromFiles(files, false);	
	// for testing
	map [loc, int] sizes = AnalyzeUnitSize(ASTDeclarations);	
	for(i <- domain(sizes)){
		println("<i> has <sizes[i]> lines.");
	}	
}

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
			case \method(_, _, _, _,Statement impl): {
				unitSize += getUnitSize(impl);
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case \constructor(_, _, _, Statement impl): {
				unitSize += getUnitSize(impl);
			}
		}
	}
	return unitSize;
}

private map [loc, int] getUnitSize(Statement s){
	list[str] filteredFile = FilterSingleFile(s.src);
	return (s.src:size(filteredFile));
}