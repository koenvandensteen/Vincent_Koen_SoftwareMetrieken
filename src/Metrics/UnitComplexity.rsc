module Metrics::UnitComplexity

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


import UnitSizeAlt;
import Helpers::HelperFunctions;

public void AnalyzeMethods()
{
	loc project = |project://smallsql|;	
	evaluateMethods(project);		
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
	// first get the line count for each method (excluding comments)
	//map [loc, int] linesOfCode = (a : size(removeCommentFromFile(a)) | a <- domain(complexity));// <- in house
	map [loc, int] linesOfCode = countMethods(project, false);// <- using UnitSizeAlt 
	// then get the total line count
	int totalLines = getRangeSum(linesOfCode);//sum([ linesOfCode[a] | a <- domain(linesOfCode)]);
	// then get one map per risk level with the lines of code of each method
	map [loc, int] lowRisk = (a:linesOfCode[a] | a <- domain(risk), risk[a] == 2);
	map [loc, int] moderateRisk = (a:linesOfCode[a] | a <- domain(risk), risk[a] == 1);
	map [loc, int] highRisk = (a:linesOfCode[a] | a <- domain(risk), risk[a] == 0);
	map [loc, int] extremeRisk = (a:linesOfCode[a] | a <- domain(risk), risk[a] == -1);
	// after that, get the relative percentage of these risk categories
	real factionLow = toReal(getRangeSum(lowRisk))/totalLines;
	real factionModerate = toReal(getRangeSum(moderateRisk))/totalLines; //sum([moderateRisk[a] | a <- domain(moderateRisk)])/totalLines;
	real factionHigh = toReal(getRangeSum(highRisk))/totalLines;//sum([highRisk[a]  | a <- domain(highRisk)])/totalLines;
	real factionExtreme = toReal(getRangeSum(extremeRisk))/totalLines;//sum([extremeRisk[a]  | a <- domain(extremeRisk)])/totalLines;
	
	println("Rounded percentage of the code per risk level:");
	println("-- Low: <toInt(factionLow*100)>%");
	println("-- Moderate: <toInt(factionModerate*100)>%");
	println("-- High: <toInt(factionHigh*100)>%");
	println("-- Extreme: <toInt(factionExtreme*100)>%");
	println("");	
	println("The overal risk level is: <getTotalRisk(factionModerate, factionHigh, factionExtreme)>.");

}
  
// from YouLearn sample
//public set[loc] javaBestanden(loc project) {
//   Resource r = getProject(project);
//   return { a | /file(a) <- r, a.extension == "java" };
//}

// 
public map [loc, int] getCyclicComplexity(set[Declaration] decls)
{
	map[loc, int] cyclicComplexity = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add complexity
			case \method(_, _, _, _,Statement impl): {
				cyclicComplexity += getCyclicComplexityMethod(impl);
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case \constructor(_, _, _, Statement impl): {
				cyclicComplexity += getCyclicComplexityMethod(impl);
			}
			// finally there are initialisers
			//case \initializer(Statement initializerBody): {
			//	cyclicComplexity += getCyclicComplexityMethod(initializerBody);
			//}
		}
	}
	return cyclicComplexity;
}

// for each method check the complexity
public map [loc, int] getCyclicComplexityMethod(Statement s){
	
	// base complexity = 1 for each started method
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
	//debug
	//println("Method <s.src> has complexity <complexity>");

	return (s.src:complexity);
}

public list[str] removeCommentFromFile(loc fileName)
{
	str textToFilter = readFile(fileName);
	list[str] returnText = removeComments(textToFilter);
	return returnText;
}

// gets the complexity rating of a method in the range [2; -1]
public int getRisk(int complexity){
	if(complexity < 11) {
		// low risk
		return 2;
	}
	else if(complexity < 21){
		// moderate risk
		return 1;
	}
	else if(complexity < 51){
		// high risk
		return 0;
	}
	else {
		// very high risk
		return -1;
	}
}

// gets the overal rating of the program in the range [2; -2]
public int getTotalRisk(real mid, real high, real extreme){
	if (mid <= 0.25 && high == 0 && extreme == 0){
		return 2;
	}
	if (mid <= 0.3 && high <= 0.05 && extreme == 0){
		return 1;
	}
	if (mid <= 0.4 && high <= 0.1 && extreme == 0){
		return 0;
	}
	if (mid <= 0.5 && high <= 0.15 && extreme <= 0.05){
		return -1;
	}
	else{
		return -2;
	}
}
