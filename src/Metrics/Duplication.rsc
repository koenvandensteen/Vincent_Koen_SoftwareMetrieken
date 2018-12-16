module Metrics::Duplication

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import Helpers::HelperFunctions;
import ListRelation;
import Helpers::DataContainers;

public int AnalyzeDuplication(projectList)
{	
	blockHashes = MapCodeOnDuplication(projectList);
	
	int countDuplicateblocks = 0;
	
	for(codeMapKeys <- blockHashes)
	{
		if(size(blockHashes[codeMapKeys])>1)
		{
			countDuplicateblocks+=6;
		}
	}
	
	return countDuplicateblocks;
}

public map[list[str],list[loc]] MapCodeOnDuplication(projectList)
{
	int blockSize = 6;
	blockList = [];
	codeMap = ();

	for(file <- projectList)
	{				
		for(i <- [1..(size(file.stringList)-blockSize)])
		{
			fileLines = file.stringList[i..i+blockSize];
			if(fileLines in codeMap)
				codeMap[fileLines]+=[file.location];
			else
				codeMap[fileLines]=[file.location];
		}
	}	
	
	return codeMap;	
}





