module Metrics::LOC

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import Helpers::HelperFunctions;
import Helpers::DataContainers;
import Agregation::SIGRating;

public int GetTotalFilteredLOC(projectList)
{
    int totalLOC = 0;
	
	for(fileLocation <- projectList)
	{
		totalLOC += size(fileLocation.stringList);
	}
	
	return totalLOC;
}

public int getTotalLOC(set[loc] fileList)
{
	int totalLines = 0;
	
	for(fileLocation <- toList(fileList))
	{
		list[str] lines = readFileLines(fileLocation);	
		totalLines += size(lines);
	}
	
	return totalLines;
}