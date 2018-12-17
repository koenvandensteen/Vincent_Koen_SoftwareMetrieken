module Helpers::HelperFunctions

import String;
import Map;
import List;
import util::Resources;

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
public set[loc] javaBestanden(loc project) {
   Resource r = getProject(project);
   return { a | /file(a) <- r, a.extension == "java" };
}

// sums up the range elements of a given map
public int getRangeSum(map [loc, int] input){

	if(size(input) == 0)
		return 0;
		
	return sum([input[a] | a <- domain(input)]);
}
