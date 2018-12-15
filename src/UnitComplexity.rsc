module UnitComplexity

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import util::Math;

import HelperFunctions;

public void AnalyzeMethods()
{
	loc project = |project://smallsql|;	
	evaluateMethods(project);	

	println("todo general: classificatie van metrieken (zie Koen)");
	
}

// based on sample from YouLearn (first few lines only)
public void evaluateMethods(loc project)
{
	// prepare AST
	set[loc] files = javaBestanden(project);
	set[Declaration] decls = createAstsFromFiles(files, false);
	// get complexity
	map [loc, int] complexity = getCyclicComplexity(decls);
	// get risk
	map [loc, int] risk = (a : getRisk(complexity[a]) | a <- domain(complexity));
	// get weighted complexity
	//(a:size(removeCommentFromFile(a))| a <- range(javaMethods));
	int linesOfCode = sum([ size(removeCommentFromFile(a)) | a <- domain(complexity)]);
	println(linesOfCode);
	//map [loc, real] weightedComplexity = ( a: toReal(complexity[a])/size(removeCommentFromFile(a))| a <- domain(complexity));
}

public int getRisk(int complexity){
	if(complexity < 11)
		return 2;
	else if(complexity < 21)
		return 1;
	else if(complexity < 51)
		return 0;
	else
		return -1;
}


   
// from YouLearn sample
public set[loc] javaBestanden(loc project) {
   Resource r = getProject(project);
   return { a | /file(a) <- r, a.extension == "java" };
}




public map [loc, int] getCyclicComplexity(set[Declaration] decls)
{
	map[loc, int] cyclicComplexity = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
			case \method(_, _, _, _,Statement s): {
				cyclicComplexity += getCyclicComplexityMethod(s);
			}
		}
	}
	return cyclicComplexity;
}

public map [loc, int] getCyclicComplexityMethod(Statement s){
	
	// base complexity = 1 for each method
	int complexity = 1;
	
	// For each of the following in the Statment (method) add one for complexity
	// based on list at http://tutor.rascal-mpl.org/Rascal/Declarations/Function/Function.html#/Rascal/Libraries/lang/java/m3/AST/Declaration/Declaration.html
	// filtered in order to only keep the "choices"
	visit(s)
	{
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
		case \defaultCase(): {
			complexity +=1;
		}
		// add one complexity for each decision related to error handling
		case \throw(_): {
			complexity += 1;
		}
		case \try(_, _): {
			complexity += 1;
		}
		case \try(_, _, _): {
			complexity += 1;
		}
		case \catch(_,_): {
			complexity += 1;
		}
		// find conditionals using the [ expr ? a : b ] structure
		case \conditional(_,_,_): {
			complexity += 1;
		}
		
	}
	println("Method <s.src> has complexity <complexity>");

	return (s.src:complexity);
}

public list[str] removeCommentFromFile(loc fileName)
{
	str textToFilter = readFile(fileName);
	list[str] returnText = removeComments(textToFilter);
	return returnText;
}

//public Declaration getAST(loc fileName, M3 model){
//	return getMethodASTEclipse(fileName, model);
//}

