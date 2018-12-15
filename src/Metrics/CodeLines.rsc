module Metrics::CodeLines

import HelperFunctions;

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import String;

import lang::java::jdt::m3::Core;

public void AnalyzeLines()
{
	loc fileName = |project://smallsql|;
	CountLines(fileName);
}

public void CountLines(loc fileName)
{
	Resource project = getProject(fileName);
	
	set[loc] FileSet = {s | /file(s) <- project ,s.extension == "java"};
	println("There are <size(FileSet)> ammount of java files in the code");
	
	
	int totalLines = 0;
		
	map[loc,int] regelsPerBestand = (a:size(readFileLines(a))|a <-FileSet);
	
	for(<loc b, int c> <- toList(regelsPerBestand))
	{
		totalLines += c;
	}
	
	//we first count naively as if there are no white lines or comments
	println("***total ammount of code with comment lines");
	println("the <fileName.uri> has <totalLines> lines of code and <size(FileSet)> classes");
	println("which averages to <totalLines/size(FileSet)> lines of code per clas");
	println("the current SIG complexity of the code is: <GetComplexityRating(totalLines)>");
	
    int totalCommentLines = 0;
	
	for(fileLocation <- toList(FileSet))
	{
		totalCommentLines += LineCountNoComment(fileLocation);
	}
	
	println("***total ammount of code without comment lines");
	println("the <fileName.uri> has <totalCommentLines> lines of comments");
	println("this makes it into ammount of code without comments and whitelines <totalCommentLines>");
	println("the current SIG complexity of the code is: <GetComplexityRating(totalLines-totalCommentLines)>");	
}

public int LineCountNoComment(loc fileName)
{
	str textToFilter = readFile(fileName);

	list[str] returnText = removeComments(textToFilter);
	println(returnText);
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