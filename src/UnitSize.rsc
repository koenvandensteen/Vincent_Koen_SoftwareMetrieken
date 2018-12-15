module UnitSize

import IO;

import List;
import Map;
import Relation;
import Set;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;

import analysis::statistics::Descriptive;

import HelperFunctions;

public void AnalyzeMethods()
{
	loc fileName = |project://smallsql|;
	CountMethods(fileName);	
}


public void CountMethods(loc fileName)
{	
	M3 model = createM3FromEclipseProject(fileName);
	
	// get all methods
	javaMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method"};
	
	// results
	int totalClasses = 0;
	int totalMethods = 0;
	int largestMethodSize = 0;
	//int smallMethodCount = 0;
	int totalMethodSize = 0;
	str largestMethod = "";
	//str largestMethodClass = "";
	real medianLines = 0.0;
	int weightedAverage = 0;
	real weightedMedian = 0.0;
	
	// intermediate vars
	//int localLines = 0;
	list [int] weightedLines = [];

	// get all methods of the program
	map[loc, int] methodCountPerClass = (a:size(javaMethods[a])| a <- domain(javaMethods));
	// get method size
	map[loc, int] methodSizes = (a:size(removeCommentFromFile(a))| a <- range(javaMethods));
	// calculate the amount of classes in the project
	totalClasses = size(domain(methodCountPerClass));
	// calculate the amount of methods in said classes
	totalMethods = sum([ size(javaMethods[a]) | a <- methodCountPerClass]);
	// find the combined method size
	totalMethodSize = sum([ methodSizes[a] | a <- domain(methodSizes)]);
	// find the largest method
	largestMethodSize = max(domain(invert(methodSizes)));
	// there may be multiple methods that share the honor to be the largest of the programm, we select one at random
	largestMethod = (getOneFrom((invert(methodSizes)[largestMethodSize]))).uri;	
	//largestMethod = (invert(methodSizes)[largestMethodSize]).uri;
	// get the median
	medianLines = median([methodSizes[a] | a <- domain(methodSizes)]);		
	//we will also make calculations with excluded short methods from this metric as these give a skewed image
	// filter out any method with less than 5 lines of code
	weightedLines = [ methodSizes[a] | a <- domain(methodSizes), methodSizes[a] > 4];
	// average
	weightedAverage = sum(weightedLines)/size(weightedLines);
	// median
	weightedMedian = median(weightedLines);	
	
	// alternative: for-loop 1
	//for(i <- methodCountPerClass){
	//	totalClasses += 1;		
	//	totalMethods += size(javaMethods[i]);		
	//}
	// alternative: for-loop 2
	//	for(j <- domain(methodSizes)){
	//		localLines = methodSizes[j];
	//		totalMethodSize += localLines;	
	//		// track largest method
	//		if(localLines>largestMethodSize){
	//			largestMethodSize = localLines;
	//			largestMethod = j.uri;
	//			//largestMethod = getMethodFromPath(j.uri);
	//			//largestMethodClass = getClassFromPath(j.uri);
	//		}
	//		// track small methods
	//		if(localLines < 5){
	//			smallMethodCount += 1;
	//		}
	//		//debug
	//		//println("Method <j> has <methodSizes[j]> lines of code, the total method size count is now <totalMethodSize> lines of code.");	
	//	}	

	println("There are <totalClasses> classes with <totalMethods> methods in  this program. This gives a total of <totalMethodSize> lines of code (LOC) excluding comments & whitelines.");
	println("This means the average loc per method equals <totalMethodSize/totalMethods> and the median is <medianLines> loc.");
	println("The largest method is <getMethodFromPath(largestMethod)> of the class <getClassFromPath(largestMethod)> with <largestMethodSize> loc.");
	println("There are <totalMethods - size(weightedLines)> small methods with fewer than 5 loc, these are often getters or setters.");
	println("If we exclude these smaller methods because of their huge impact on this metric we see the new average is <weightedAverage> loc per method and the median is <weightedMedian> loc per method");
	println("The complexity rating of the program is then: XXXX_TO_BE_DONE_XXXX.");
	// use getComplexityRating(int weightedLineCount)
	
	println("");
	println("Volgende stappen: ");
	println("1 - goede methode om een uitgemiddeld resultaat uit te zoeken, e.g. getters en setters van 1 regel code hebben te grote impact. Statistisch, mediaan,...?");
	println("2 - classificeren (zie hulpmethode onderaan)");

}

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

public str getMethodFromPath(str s){
	int i = findLast(s, "/");
	return substring(s, i + 1);
}

public str getClassFromPath(str s){
	str help = "";
	int i = findLast(s, "/");
	help = substring(s, 1, i);
	i = findLast(help, "/");
	return substring(help, i + 1);
}