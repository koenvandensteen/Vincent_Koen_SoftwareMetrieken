module Main

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import util::Math;
import util::Resources;
import DateTime;
import List;

import Helpers::HelperFunctions;
import Helpers::DataContainers;

import Metrics::LOC;
import Metrics::UnitComplexity;
import Metrics::UnitSizeAlt;
import Metrics::Duplication;

import Agregation::SIGRating;

import util::Math;

public void AnalyzeAllProjects()
{
	println("******* START ANALYZE JABBERPOINT *********");
	AnalyzeProject(|project://Jabberpoint|,"jabberPoint");
	println("******* START ANALYZE smallsql *********");
	AnalyzeProject(|project://smallsql|,"smallsql");
	println("******* START ANALYZE hsqldb *********");
	AnalyzeProject(|project://hsqldb|,"hsqldb");
}

public void AnalyzeProject(loc locProject, str projectName)
{
	startMoment = now();
	
	list[str] totalReport = [];
	M3 m3Project = createM3FromEclipseProject(locProject);
	

	
	totalReport+="**** analys started at: <startMoment> \n";
	println(totalReport[size(totalReport)-1]);
	
	//regular file count
	allFiles = files(m3Project);
	int totalLines = getTotalLOC(allFiles);
	totalReport+="total lines unfiltered: <totalLines>\n";
	println(totalReport[size(totalReport)-1]);	
	/*
	//LOC Metric
	*/
	projectList filteredProject = FilterAllFiles(allFiles);		
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	println("total lines filtered: <filteredLineCount>\n");
	int volumeRating = GetSigRatingLOC(filteredLineCount);
	totalReport+="**** line count SIG-rating: <transFormSIG(volumeRating)>\n";
	println(totalReport[size(totalReport)-1]);	
	/*
	//Unit Complexity Metric
	*/
	unitComplexityRating = AnalyzeUnitComplexity(locProject);
		
	for(key <- unitComplexityRating)
	{
		totalReport+="percentage <key> risk units: <round(unitComplexityRating[key]*100,0.01)>%\n";
			println(totalReport[size(totalReport)-1]);
	}
	
	int overalComplexityRating = GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]);
	totalReport+="**** unity complexity SIG-rating: <transFormSIG(overalComplexityRating)>\n";
	println(totalReport[size(totalReport)-1]);
	/*
	//duplication Metric
	*/
	int duplicatedLines = AnalyzeDuplication(filteredProject);
	println("total lines duplicated: <duplicatedLines>\n");
	num duplicatePercentage = (duplicatedLines/(filteredLineCount/100.000));
	println("total lines duplicated percentage: <round(duplicatePercentage,0.01)>%\n");
	int duplicationRating = GetDuplicationRating(duplicatePercentage);
	totalReport+="**** duplication SIG-rating: <transFormSIG(duplicationRating)>\n";
	println(totalReport[size(totalReport)-1]);
	/*
	//unitSizeRating Metric
	*/
	unitSizeRating = AnalyzeUnitSize(locProject);
	
	for(key <- unitSizeRating)
	{
		totalReport+="percentage <key> unit sizes: <round(unitSizeRating[key]*100,0.01)>%\n";
	println(totalReport[size(totalReport)-1]);
	}
	
	int overalUnitSizeRating = GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]);
	totalReport+="**** unity size SIG-rating: <transFormSIG(overalUnitSizeRating)>\n";
	println(totalReport[size(totalReport)-1]);
	/*
	//unit Test Rating metric
	*/
	int unitTestingRating = 0;
	//TODO MAKE THIS HAPEN
		
	maintabilityRating = GetMaintabilityRating(volumeRating, overalComplexityRating, duplicationRating, overalUnitSizeRating, unitTestingRating);
	totalReport+="**** analysability: <transFormSIG(maintabilityRating.analysability)>\n";
	println(totalReport[size(totalReport)-1]);
	totalReport+="**** changeability: <transFormSIG(maintabilityRating.changeability)>\n";
	println(totalReport[size(totalReport)-1]);
	totalReport+="**** stability: <transFormSIG(maintabilityRating.changeability)>\n";
	println(totalReport[size(totalReport)-1]);
	totalReport+="**** testability: <transFormSIG(maintabilityRating.changeability)>\n";
	println(totalReport[size(totalReport)-1]);
	
	totalReport+="<locProject> has been analyzed and receives an overal rating of: <transFormSIG(GetTotalSIGRating(maintabilityRating))>\n";
	println(totalReport[size(totalReport)-1]);
	endMoment = now();
	executionDuration = createDuration(startMoment,endMoment);
	totalReport+="**** analys ended at: <now()> and took <executionDuration.minutes> minutes <executionDuration.seconds> seconds <executionDuration.milliseconds> milliseconds \n\n\n\n\n";
	println(totalReport[size(totalReport)-1]);
		
	loc writeDestination = |project://SoftwareEvolution/|;
	writeDestination.uri += "/<projectName>metrics.txt";
	println(writeDestination.uri);
	writeFile(writeDestination, totalReport);

}
