module Metrics::Duplication

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import HelperFunctions;
import ListRelation;


public void AnalyzeDuplication()
{
	loc fileName = |project://hsqldb|;
	M3 m3Project = createM3FromEclipseProject(fileName);
	lrel[loc location,list[str] stringList] filteredProject = FilterAllFiles(files(m3Project));
	
	blockHashes = MapCodeOnDuplication(filteredProject);
	
	int countDuplicatblocks = 0;
	
	for(codeMapKeys <- blockHashes)
	{
		//
		if(size(blockHashes[codeMapKeys])>=2)
		{
			println("***** this block appeared <size(blockHashes[codeMapKeys])> times: <codeMapKeys>");
			println("***** in <blockHashes[codeMapKeys]>");
		}
	}
	

}



public lrel[loc location,list[str] stringList] FilterAllFiles(set[loc] fileList)
{
	lrel[loc,list[str]] returnList = [];
	
	for(fileName <- fileList)
	{
		str textToFilter = readFile(fileName);
		list[str] filteredText = removeComments(textToFilter);
		returnList += <fileName,filteredText>;
	}
	
	return returnList;
}

public map[list[str],list[loc]] MapCodeOnDuplication(lrel[loc location,list[str] stringList] projectFiles)
{
	int blockSize = 6;
	blockList = [];
	codeMap = ();
	
	for(file <- projectFiles)
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

public str HashValue(list[str] stringList)
{
	
	return "";
}







