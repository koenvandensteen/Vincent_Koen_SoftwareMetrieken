module Helpers::HelperFunctions

import String;
import Map;
import List;
import util::Resources;
import util::Math;

import lang::java::m3::AST;


import IO;

public lrel[loc location,list[str] stringList] FilterAllFiles(set[loc] fileList)
{
	lrel[loc,list[str]] returnList = [];
	
	for(fileName <- fileList)
	{
		returnList += <fileName,FilterSingleFile(fileName)>;
	}
	
	return returnList;
}

public list[str] FilterSingleFile(loc fileName)
{
	str textToFilter = readFile(fileName);
	list[str] returnText = removeComments(textToFilter);	
	return returnText;
}

public list[str] removeComments(str inputString)
{	
	str noComments = visit(inputString)
	{
		case /(\/\*[\s\S]*?\*\/)|(\/\/.*)/ => "" //multi line comments
	};
			
	list[str] lines = split("\n", noComments);
	//we replaced previous lines with white lines so now we clean the regular ones and the ones we added
    return [trim(line) | line <- lines, !isWhiteLine(line)];  				
}

private bool isWhiteLine(str line) {
   	return isEmpty(trim(line));
}

// from YouLearn sample
public set[loc] getFilesJava(loc project) {
   Resource r = getProject(project);
   return { a | /file(a) <- r, a.extension == "java" };
}

// sums up the range elements of a given map
public int getRangeSum(map [loc, int] input){

	if(size(input) == 0)
		return 0;
		
	return sum([input[a] | a <- domain(input)]);
}

// filters negative values
public map[loc, int] getPositives(map [loc, int] input){

	if(size(input) == 0)
		return [];
		
	return (a:input[a] | a <- domain(input), input[a] >= 0);
}


public map[str, real] getRiskFactions(map [loc, int] metricMap, map [loc, int] risk){

	real factionLow  = 0.0;
	real factionModerate = 0.0;
	real factionHigh = 0.0;
	real factionExtreme = 0.0;

	int metricSize = getRangeSum(metricMap);
	// then get one map per risk level with the lines of code of each method
	map [loc, int] lowRisk = (a:metricMap[a] | a <- domain(risk), risk[a] == 1);
	map [loc, int] moderateRisk = (a:metricMap[a] | a <- domain(risk), risk[a] == 0);
	map [loc, int] highRisk = (a:metricMap[a] | a <- domain(risk), risk[a] == -1);
	map [loc, int] extremeRisk = (a:metricMap[a] | a <- domain(risk), risk[a] == -2);
	// after that, get the relative percentage of these risk categories
	factionLow = toReal(getRangeSum(lowRisk))/metricSize;
	factionModerate = toReal(getRangeSum(moderateRisk))/metricSize; 
	factionHigh = toReal(getRangeSum(highRisk))/metricSize;
	factionExtreme = toReal(getRangeSum(extremeRisk))/metricSize;
	
	return ("factionLow":factionLow,"factionModerate":factionModerate,"factionHigh":factionHigh,"factionExtreme":factionExtreme);
}

public map[loc, str] getLocsNames(set[Declaration] decls){

	map[loc, str] locNameList = ();

	visit(decls){
		case m: \method(_, _, _, _, _): {
			locNameList += (m.src:m.name);
		}
		case m: \constructor(_, _, _, _): {
			locNameList += (m.src:m.name);
		}
	}
	
	return locNameList;
}

// calculates the relative quanitity of "target" using "base"
public map[loc, real] getRelativeRate(map[loc, int] base, map[loc, int] target){
	
	map[loc, real] retVal = ();
	
	for(i <- domain(base)){
		if(i in target){
			retVal[i] = round(toReal(target[i])/base[i]*100.0,0.01);
		}
		else{
			retVal[i] = 0.0;
		}
	}
	
	return retVal;
}


// sees if junit.framework is imported in a class
public bool isTestClass(Declaration d){
	Declaration file;

	visit(d) {  
		// if everything was tested with junit, the first case below should have been enough
		case \import(str name): {	
			if( /.*junit.framework.*/ := name){
				return true;
			}
		}
		case \class(str name, _, _, _): {
			if( /.*test.*/ := name || /.*Test.*/ := name){
				return true;
			}
		}
	}

	return false;		
}

//gets the common path of a set of java files
public str getCommonPath(set[loc] files){

	map[loc, list[str]] substrings = ();
	bool stillEqual = true;
	str firstVal = "";
	int counter = 0;
	int minSize = -1;
	str retVal = "";
	
	for(i <- files){
		substrings += (i:split("/", i.path));
		if(minSize == -1 || minSize > size(substrings))
			minSize = size(substrings);
	}
	
	while(stillEqual && counter <= minSize + 1){
		for(i <- domain(substrings)){
			if(firstVal == "")
				firstVal = substrings[i][counter];
				
			stillEqual = (firstVal == substrings[i][counter]);

		}
		if(stillEqual){	
			counter += 1;
			if(retVal == "") // first assignment does not need the /
				retVal = firstVal;
			else if(!(firstVal == ""))
				retVal = retVal + "/" + firstVal;
			firstVal = "";	
		}	
	}
	
	return retVal;
}