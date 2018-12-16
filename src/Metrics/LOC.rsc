module Metrics::LOC

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import HelperFunctions;

public void AnalyzeLines()
{
	loc fileName = |project://Jabberpoint|;
	CountLines(fileName);
}

public void CountLines(loc fileName)
{	
	M3 m3Project = createM3FromEclipseProject(fileName);
	
	int totalLines = getTotalCountLineCount(files(m3Project));
	int filteredLines = GetTotalFilteredLineCount(files(m3Project));
			
	//we first count naively as if there are no white lines or comments
	println("***total ammount of code with comment lines");
	println("the <fileName.uri> has <totalLines> lines of code and <size(files(m3Project))> classes");
	println("the current SIG complexity of the code is: <GetComplexityRating(totalLines)>");
		
	println("***total ammount of code without comment lines");
	println("the <fileName.uri> has <totalLines-filteredLines> lines of comments");
	println("this makes it into ammount of code without comments and whitelines <filteredLines>");
	println("the current SIG complexity of the code is: <GetComplexityRating(filteredLines)>");	
}

public int GetTotalFilteredLineCount(set[loc] fileList)
{
    int totalLOC = 0;
	
	for(fileLocation <- toList(fileList))
	{
		totalLOC += LineCountNoComment(fileLocation);
	}
	
	return totalLOC;
}

public int getTotalCountLineCount(set[loc] fileList)
{
	int totalLines = 0;
	
	for(fileLocation <- toList(fileList))
	{
		list[str] lines = readFileLines(fileLocation);	
		totalLines += size(lines);
	}
	
	return totalLines;
}

public int LineCountNoComment(loc fileName)
{
	str textToFilter = readFile(fileName);

	list[str] returnText = removeComments(textToFilter);
	return size(returnText);
}

public int GetComplexityRating(int totalLinesOfCode)
{
	if(totalLinesOfCode < 66000)
		return 2;
	else if(totalLinesOfCode < 246000)
		return 1;
	else if(totalLinesOfCode < 665000)
		return 0;
	else if(totalLinesOfCode < 1310000)
		return -1;
	else
		return -2;
}