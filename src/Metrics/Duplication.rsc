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

public void AnalyzeDuplication()
{
	loc fileName = |project://hsqldb|;
	M3 m3Project = createM3FromEclipseProject(fileName);
	lrel[loc location,list[str] stringList] filteredProject = FilterAllFiles(files(m3Project));
	
	blockHashes = MapCodeOnDuplication(filteredProject);
	
	int countDuplicateblocks = 0;
	
	for(codeMapKeys <- blockHashes)
	{
		if(size(blockHashes[codeMapKeys])>1)
		{
			countDuplicateblocks+=6;
		}
	}
}

public map[list[str],list[loc]] MapCodeOnDuplication(projectList)
{
	int blockSize = 6;
	blockList = [];
	codeMap = ();
	int progressCounter = 0;
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
		progressCounter+=6;
		println("printed file number <progressCounter> of <size(projectList)>");
	}	
	return codeMap;	
}





