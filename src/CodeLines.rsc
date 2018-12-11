module CodeLines

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import String;

public void AnalyzeLines()
{
	loc fileName = |project://Jabberpoint|;
	
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
		totalCommentLines += CommentCount(fileLocation);
	}
	
	println("***total ammount of code without comment lines");
	println("the <fileName.uri> has <totalCommentLines> lines of comments");
	println("this makes it into ammount of code without comments and whitelines <totalLines-totalCommentLines>");
	println("the current SIG complexity of the code is: <GetComplexityRating(totalLines-totalCommentLines)>");	
}

public int CommentCount(loc fileName)
{
	str textToFilter = readFile(fileName);

	//println("*****Unfiltered text <fileName> linesize: <size(readFileLines(fileName))>******");
	
	//we first filter on block comments, then we check on single line comments and then on empty lines.
	list[str] filtered = [t | /<t:(\/\*(.|[\r\n])*?\*\/)|(\/\/.*)|(\n\s*\r)>/ := textToFilter];
	int commentCounter = 0;
	for(listItem <- filtered)
	{
		list[str] returnList = split("\r\n",listItem);
		commentCounter+=size(returnList);
	}
	
	//println("*****ammount of comment lines in: <fileName> : <commentCounter>******");
	//println("*****Actual code lines in <fileName> = <size(readFileLines(fileName))-commentCounter>******");	

	return commentCounter;
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