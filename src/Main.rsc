module Main

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import util::Math;
import util::Resources;
import DateTime;
import List;
import Map;

import Helpers::HelperFunctions;
import Helpers::DataContainers;

import Metrics::LOC;
import Metrics::UnitComplexity;
import Metrics::UnitSizeAlt;
import Metrics::Duplication;
import Metrics::UnitTests;

import Testing::TestRascal;

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

public void RunTestProgram(){
	// run test module
	println("******* CHECK PROGRAM VALIDITY *********");
	TestAll();
	println();
	// run main with test project
	println("******* START ANALYZE TEST PROJECT *********");
	AnalyzeProject(|project://SimpleJavaDemo|,"Test Project");
}

public void AnalyzeProject(loc locProject, str projectName)
{
	startMoment = now();
	
	list[str] totalReport = [];
	M3 m3Project = createM3FromEclipseProject(locProject);
	
	//prepare ast globally
	set[loc] javaFiles = getFilesJava(locProject);
	set[Declaration] ASTDeclarations = createAstsFromFiles(javaFiles, false);

	
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
	//unitSizeRating Metric
	*/
	unitSizeMap = AnalyzeUnitSize(ASTDeclarations); 
	unitSizeRisk = (a : GetUnitSizeRisk(unitSizeMap[a]) | a <- domain(unitSizeMap));
	unitSizeRating = getRiskFactions(unitSizeMap, unitSizeRisk);

	for(key <- unitSizeRating)
	{
		totalReport+="percentage <key> unit sizes: <round(unitSizeRating[key]*100,0.01)>%\n";
	println(totalReport[size(totalReport)-1]);
	}
	
	int overalUnitSizeRating = GetUnitComplexityRating(unitSizeRating["factionModerate"], unitSizeRating["factionHigh"], unitSizeRating["factionExtreme"]);
	totalReport+="**** unity size SIG-rating: <transFormSIG(overalUnitSizeRating)>\n";
	println(totalReport[size(totalReport)-1]);
	/*
	//Unit Complexity Metric
	*/
	unitComplexityMap = AnalyzeUnitComplexity(ASTDeclarations);
	unitComplexityRisk = (a : GetUnitComplexityRisk(unitComplexityMap[a]) | a <- domain(unitComplexityMap));
	unitComplexityRating = getRiskFactions(unitSizeMap, unitComplexityRisk);
		
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
	//unit Test Rating metric
	*/
	
	//TODO MAKE THIS HAPEN
	tuple[real v1, real v2] unitTestCoverage = AnalyzeUnitTest(ASTDeclarations);
	println("Naive test coverage based on method pairing: <round(unitTestCoverage.v1*100,0.01)>% - risk factor:<transFormSIG(getTestRating(unitTestCoverage.v1))>\n");
	println("Test coverage based on assert count: <round(unitTestCoverage.v2*100,0.01)>% - risk factor: <transFormSIG(getTestRating(unitTestCoverage.v2))>\n");
	// selected the more representative assert count method for further metrics
	int unitTestingRating = getTestRating(unitTestCoverage.v2);
	totalReport+="**** test coverage SIG-rating: <transFormSIG(unitTestingRating)>\n";
	println(totalReport[size(totalReport)-1]);
	
	//
		
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
