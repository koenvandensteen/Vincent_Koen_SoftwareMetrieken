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

import Helpers::HelperFunctions;

import Metrics::UnitSize;
import Metrics::UnitSizeAlt;

// based on sample from YouLearn (first few lines only)
public map [str, real] AnalyzeUnitComplexity(set[Declaration] ASTDeclarations)
{
	// prepare AST <- done globally 
	// get complexity
	map [loc, int] complexity = getCyclicComplexity(ASTDeclarations);
	// get risk
	map [loc, int] risk = (a : getRisk(complexity[a]) | a <- domain(complexity));
	// get weighted complexity
	// first get the line count for each method (excluding comments)
	map [loc, int] linesOfCode = countMethods(ASTDeclarations);// <- using UnitSizeAlt 
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
		
	return ("factionLow":factionLow,"factionModerate":factionModerate,"factionHigh":factionHigh,"factionExtreme":factionExtreme);
}
  
// also used by "outside" methods 
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
		}
	}
	return cyclicComplexity;
}

// for each method check the complexity
private map [loc, int] getCyclicComplexityMethod(Statement s){

	// programmable: should exception handling be counted -> int = 1; if not int = 0;
	int countExceptions = 1;
	
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
			complexity += countExceptions;
		}
		case \try(_, _): {
			complexity += countExceptions;
		}
		case \try(_, _, _): {
			complexity += countExceptions;
		}
		case \catch(_,_): {
			complexity += countExceptions;
		}
		// find conditionals using the [ expr ? a : b ] structure
		case \conditional(_,_,_): {
			complexity += 1;
		}		
	}


	return (s.src:complexity);
}

// gets the complexity rating of a method in the range [2; -1]
private int getRisk(int complexity){
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