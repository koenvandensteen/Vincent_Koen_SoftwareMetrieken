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


public void analyzeMethodSize()
{
	loc project = |project://smallsql|;	
	countMethods(project, true);		
}

// based on sample from YouLearn (first few lines only)
public map[loc, int] countMethods(loc project, bool print)
{
	// prepare AST
	set[loc] files = javaBestanden(project);
	set[Declaration] decls = createAstsFromFiles(files, false);
	map[loc, int] unitSizes = getUnitSizeMap(decls);
	int totalSize = getRangeSum(unitSizes); //sum([unitSizes[a] | a <- domain(unitSizes)]);
	if(print){
		// extra vars
		int treshold = 5;
		int methodCount =size(domain(unitSizes));
		num baseAverage = totalSize/size(domain(unitSizes));
		num baseMedian = median([unitSizes[a] | a <- domain(unitSizes)]);
		// weighted
		list [int] weightedLines = [ unitSizes[a] | a <- domain(unitSizes), unitSizes[a] > treshold];
		num weightedAverage = sum(weightedLines)/size(weightedLines);
		num weightedMedian = median(weightedLines);	
		// max
		largestMethodSize = max(domain(invert(unitSizes)));// find the largest method
		largestMethod = (getOneFrom((invert(unitSizes)[largestMethodSize]))).uri;	// there may be multiple methods that share the honor to be the largest of the programm, we select one at random
		//printing
		println("There are <totalSize> lines of code in the <methodCount> methods of this project.");
		println("That means the (rounded) average is <baseAverage> lines of code per method.");
		println("The median is lines of code per method is <baseMedian>");	
		println("");
		println("There are <methodCount - size(weightedLines)> methods with fewer than <treshold> lines of code.");	
		println("These are often simple getters/setters but affect the average and median strongly.");
		println("We exclude these very small methods and calculate the new average: <weightedAverage>, and median: <weightedMedian>");
		println("This gives a better representation of the project."); 
		println("The largest method is <largestMethodSize> lines of code long. It is found in the <getClassFromPath(largestMethod)> package.");
		println("To be done: quota for qualification and quantification of unit sizes!!!!!!!!!");

		
	}
	return unitSizes;
}

// 
public map [loc, int] getUnitSizeMap(set[Declaration] decls)
{
	map[loc, int] unitSize = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add lines of code to the actual methods
			case \method(_, _, _, _,Statement impl): {
				unitSize += getUnitSize(impl);
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case \constructor(_, _, _, Statement impl): {
				unitSize += getUnitSize(impl);
			}
			// finally there are initialisers
			//case \initializer(Statement initializerBody): {
			//	unitSize += getUnitSize(initializerBody);
			//}
		}
	}
	return unitSize;
}

public map [loc, int] getUnitSize(Statement s){
	return (s.src:size(removeCommentFromFile(s.src)));
}

// refactor candidate: komt voor in 3 modules
public list[str] removeCommentFromFile(loc fileName)
{
	str textToFilter = readFile(fileName);
	list[str] returnText = removeComments(textToFilter);
	return returnText;
}

public int getComplexityRating(int weightedLinesOfCode)
{
	if(weightedLinesOfCode < 20)
		return 2;
	else if(weightedLinesOfCode < 30)
		return 1;
	else if(weightedLinesOfCode < 40)
		return 0;
	else if(weightedLinesOfCode < 50)
		return -1;
	else
		return -2;
}

private str getMethodFromPath(str s){
	int i = findLast(s, "/");
	return substring(s, i + 1);
}

private str getClassFromPath(str s){
	str help = "";
	int i = findLast(s, "/");
	help = substring(s, 1, i);
	i = findLast(help, "/");
	return substring(help, i + 1);
}