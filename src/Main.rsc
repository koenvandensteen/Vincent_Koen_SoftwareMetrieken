module Main

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import util::Math;
import util::Resources;


import Helpers::HelperFunctions;
import Helpers::DataContainers;

import Metrics::LOC;
import Metrics::UnitComplexity;
import Metrics::Duplication;

import Agregation::SIGRating;

import util::Math;

public void AnalyzeAllProjects()
{
	println("******* START ANALYZE JABBERPOINT *********");
	AnalyzeProject(|project://Jabberpoint|);
	/*println("******* START ANALYZE smallsql *********");
	AnalyzeProject(|project://smallsql|);
	println("******* START ANALYZE hsqldb *********");
	AnalyzeProject(|project://hsqldb|);*/
}

public void AnalyzeProject(loc locProject)
{
	M3 m3Project = createM3FromEclipseProject(locProject);
	
	//regular file count
	allFiles = files(m3Project);
	int totalLines = getTotalLOC(allFiles);
	println("total lines unfiltered: <totalLines>");

	//filtered line count
	projectList filteredProject = FilterAllFiles(allFiles);		
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	println("total lines filtered: <filteredLineCount>");
	println("line count SIG-rating: <transFormSIG(GetSigRatingLOC(filteredLineCount))>");
	
	int duplicatedLines = AnalyzeDuplication(filteredProject);
	println("total lines duplicated: <duplicatedLines>");
	num duplicatePercentage = (duplicatedLines/(filteredLineCount/100.000));
	println("total lines duplicated percentage: <round(duplicatePercentage,0.01)>");
	println("line count SIG-rating: <transFormSIG(GetDuplicationRating(duplicatePercentage))>");
	
	unitComplexityRating = AnalyzeUnitComplexity(locProject);
	
	println("Rounded percentage of the code per risk level:");
	
	for(key <- unitComplexityRating)
	{
		println("percentage <key> risk units: <round(unitComplexityRating[key]*100,0.01)>%");
	}
	
	println("The overal risk level is: <transFormSIG(GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]))>.");


}