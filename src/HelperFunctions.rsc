module HelperFunctions

import String;
import Map;
import List;
import util::Resources;


public list[str] removeComments(str inputString)
{	
	str noComments = visit(inputString)
	{
		case /\/\*[\s\S]*?\*\/|\/\/.*/ => "" //multi line comments
	};
			
	list[str] lines = split("\n", noComments);
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
	return sum([input[a] | a <- domain(input)]);
}
