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
	map [loc, int] linesOfCode = (a : size(removeCommentFromFile(a)) | a <- domain(complexity));
	// then get the total line count
	int totalLines = sum([ linesOfCode[a] | a <- domain(linesOfCode)]);
	// then get one map per risk level with the lines of code of each method
	map [loc, real] lowRisk = (a:toReal(linesOfCode[a]) | a <- domain(risk), risk[a] == 2);
	map [loc, real] moderateRisk = (a:toReal(linesOfCode[a]) | a <- domain(risk), risk[a] == 1);
	map [loc, real] highRisk = (a:toReal(linesOfCode[a])  | a <- domain(risk), risk[a] == 0);
	map [loc, real] extremeRisk = (a:toReal(linesOfCode[a])  | a <- domain(risk), risk[a] == -1);
	// after that, get the relative percentage of these risk categories
	real factionLow = sum([lowRisk[a] | a <- domain(lowRisk)])/totalLines;
	real factionModerate = sum([moderateRisk[a] | a <- domain(moderateRisk)])/totalLines;
	real factionHigh = sum([highRisk[a]  | a <- domain(highRisk)])/totalLines;
	real factionExtreme = sum([extremeRisk[a]  | a <- domain(extremeRisk)])/totalLines;
	
	println("Rounded percentage of the code per risk level:");
	println("-- Low: <toInt(factionLow*100)>%");
	println("-- Moderate: <toInt(factionModerate*100)>%");
	println("-- High: <toInt(factionHigh*100)>%");
	println("-- Extreme: <toInt(factionExtreme*100)>%");
	println("");	
	println("The overal risk level is: <getTotalRisk(factionModerate, factionHigh, factionExtreme)>.");
	
	//map [loc, real] weightedComplexity = ( a: toReal(complexity[a])/size(removeCommentFromFile(a))| a <- domain(complexity));
}

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

//public Declaration getAST(loc fileName, M3 model){
//	return getMethodASTEclipse(fileName, model);
//}

