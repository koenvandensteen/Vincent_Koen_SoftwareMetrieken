module HelperFunctions

import String;


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