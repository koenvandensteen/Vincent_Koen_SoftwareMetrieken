module Main

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;


import Helpers::HelperFunctions;
import Metrics::LOC;


public void AnalyzeAllProjects()
{
	AnalyzeProject(|project://Jabberpoint|);
}

public void AnalyzeProject(loc locProject)
{
	M3 m3Project = createM3FromEclipseProject(locProject);
	
	//regular file count
	int totalLines = getTotalCountLineCount(files(m3Project));
	
	lrel[loc location,list[str] stringList] filteredProject = FilterAllFiles(files(m3Project));		
	
	int filteredLineCount = 
}