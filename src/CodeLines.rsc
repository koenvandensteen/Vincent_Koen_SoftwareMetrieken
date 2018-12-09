module CodeLines

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;

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
	
	map[loc,int] regelsPerBestand = (a:size(readFileLines(a))|a <-FileSet);
	
	int totalLines = 0;
	
	for(<loc b, int c> <- toList(regelsPerBestand))
	{
		totalLines += c;
	}
	
	println("the <fileName.uri> has <totalLines> lines of code and <size(FileSet)> classes");
	println("which averages to <totalLines/size(FileSet)> lines of code per clas");
	println("the current SIG complexity of the code is: <GetComplexityRating(totalLines)>");
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