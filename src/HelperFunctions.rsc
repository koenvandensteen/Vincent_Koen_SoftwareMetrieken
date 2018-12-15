module HelperFunctions

import String;

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