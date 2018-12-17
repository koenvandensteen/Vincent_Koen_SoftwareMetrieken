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
import Metrics::UnitSize;
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
	list[str] totalReport = [];
	startMoment = now();	
	totalReport+=PrintAndReturnString("**** analasys started at: <startMoment>");

	M3 m3Project = createM3FromEclipseProject(locProject);
	
	//prepare ast globally
	set[loc] javaFiles = getFilesJava(locProject);
	set[Declaration] ASTDeclarations = createAstsFromFiles(javaFiles, false);


	//regular file count
	allFiles = files(m3Project);
	int totalLines = getTotalLOC(allFiles);
	totalReport+=PrintAndReturnString("total lines unfiltered: <totalLines>");
	
	/*
	//LOC Metric
	*/
	projectList filteredProject = FilterAllFiles(allFiles);		
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	totalReport+=PrintAndReturnString("total lines filtered: <filteredLineCount>");
	int volumeRating = GetSigRatingLOC(filteredLineCount);
	totalReport+=PrintAndReturnString("**** line count SIG-rating: <transFormSIG(volumeRating)>");
	println("\n");
	
	/*
	//unitSizeRating Metric
	*/
	unitSizeMap = AnalyzeUnitSize(ASTDeclarations); 
	unitSizeRisk = (a : GetUnitSizeRisk(unitSizeMap[a]) | a <- domain(unitSizeMap));
	unitSizeRating = getRiskFactions(unitSizeMap, unitSizeRisk);

	for(key <- unitSizeRating)
	{
		totalReport+=PrintAndReturnString("percentage <key> unit sizes: <round(unitSizeRating[key]*100,0.01)>%");
	}
	
	int overalUnitSizeRating = GetUnitComplexityRating(unitSizeRating["factionModerate"], unitSizeRating["factionHigh"], unitSizeRating["factionExtreme"]);
	
	totalReport+=PrintAndReturnString("**** unit size SIG-rating: <transFormSIG(overalUnitSizeRating)>");
	println("\n");
	
	/*
	//Unit Complexity Metric
	*/
	unitComplexityMap = AnalyzeUnitComplexity(ASTDeclarations);
	unitComplexityRisk = (a : GetUnitComplexityRisk(unitComplexityMap[a]) | a <- domain(unitComplexityMap));
	unitComplexityRating = getRiskFactions(unitSizeMap, unitComplexityRisk);
		
	for(key <- unitComplexityRating)
	{
		totalReport+=PrintAndReturnString("percentage <key> risk units: <round(unitComplexityRating[key]*100,0.01)>%");
	}
	
	int overalComplexityRating = GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]);	
	totalReport+=PrintAndReturnString("**** unit complexity SIG-rating: <transFormSIG(overalComplexityRating)>");
	println("\n");
	
	/*
	//duplication Metric
	*/
	int duplicatedLines = AnalyzeDuplication(filteredProject);
	totalReport+=PrintAndReturnString("total lines duplicated: <duplicatedLines>");
	num duplicatePercentage = (duplicatedLines/(filteredLineCount/100.000));
	totalReport+=PrintAndReturnString("total lines duplicated percentage: <round(duplicatePercentage,0.01)>%");
	int duplicationRating = GetDuplicationRating(duplicatePercentage);
	totalReport+=PrintAndReturnString("**** duplication SIG-rating: <transFormSIG(duplicationRating)>");
	println("\n");
	
	/*
	//unit Test Rating metric
	*/	
	tuple[real v1, real v2] unitTestCoverage = AnalyzeUnitTest(ASTDeclarations);
	println("Naive test coverage based on method pairing: <round(unitTestCoverage.v1*100,0.01)>% - risk factor:<transFormSIG(getTestRating(unitTestCoverage.v1))>");
	totalReport+=PrintAndReturnString("Test coverage based on assert count: <round(unitTestCoverage.v2*100,0.01)>% - risk factor: <transFormSIG(getTestRating(unitTestCoverage.v2))>");
	// selected the more representative assert count method for further metrics
	int unitTestingRating = getTestRating(unitTestCoverage.v2);
	totalReport+=PrintAndReturnString("**** test coverage SIG-rating: <transFormSIG(unitTestingRating)>");
	println("\n");
	
	/*
	//Overal agregation of data
	*/			
	maintabilityRating = GetMaintabilityRating(volumeRating, overalComplexityRating, duplicationRating, overalUnitSizeRating, unitTestingRating);
	totalReport+=PrintAndReturnString("**** analysability: <transFormSIG(maintabilityRating.analysability)>");
	totalReport+=PrintAndReturnString("**** changeability: <transFormSIG(maintabilityRating.changeability)>");
	totalReport+=PrintAndReturnString("**** stability: <transFormSIG(maintabilityRating.stability)>");
	totalReport+=PrintAndReturnString("**** testability: <transFormSIG(maintabilityRating.testability)>");
	totalReport+=PrintAndReturnString("<locProject> has been analyzed and receives an overal rating of: <transFormSIG(GetTotalSIGRating(maintabilityRating))>");
	
	totalReport+=PrintAndReturnString("\n");
	totalReport+=PrintAndReturnString("\n");
	
	totalReport+=PrintAndReturnString("ISO 9126 mainainability chart");
	totalReport+=PrintAndReturnString("______________________________");
	totalReport+=PrintAndReturnString("     | V | U | D | U | U || T ");	
	totalReport+=PrintAndReturnString("     | O | N | U | N | N || O ");	
	totalReport+=PrintAndReturnString("     | L | T | P | T | T || T ");
	totalReport+=PrintAndReturnString("     | U | C | L | S | T || A ");
	totalReport+=PrintAndReturnString("     | M | M | I | I | S || L ");
	totalReport+=PrintAndReturnString("     | E | X | C | Z | T || * ");
	totalReport+=PrintAndReturnString("-----|---|---|---|---|---||---");
	totalReport+=PrintAndReturnString("ANALY|<transFormSIG(volumeRating)> |   |<transFormSIG(duplicationRating)> |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.analysability)>");
	totalReport+=PrintAndReturnString("CHANG|   |<transFormSIG(overalComplexityRating)> |<transFormSIG(duplicationRating)> |   |   ||<transFormSIG(maintabilityRating.changeability)>");
	totalReport+=PrintAndReturnString("STABI|   |   |   |   |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.stability)>");
	totalReport+=PrintAndReturnString("TESTA|   |<transFormSIG(overalComplexityRating)> |   |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.testability)>");
	totalReport+=PrintAndReturnString("-----|---|---|---|---|---||---");
	totalReport+=PrintAndReturnString("TOTAL|---|---|---|---|---||<transFormSIG(GetTotalSIGRating(maintabilityRating))> ");
	totalReport+=PrintAndReturnString("\n");
	totalReport+=PrintAndReturnString("\n");
	
	
	endMoment = now();
	executionDuration = createDuration(startMoment,endMoment);
	totalReport+=PrintAndReturnString("**** analys ended at: <now()> and took <executionDuration.minutes> minutes <executionDuration.seconds> seconds <executionDuration.milliseconds> milliseconds \n\n\n\n\n");
		
	loc writeDestination = |project://SoftwareEvolution/|;
	writeDestination.uri += "/<projectName>metrics.txt";
	println(writeDestination.uri);
	writeFile(writeDestination, totalReport);
}


private str PrintAndReturnString(str message)
{
	println(message);
	return message+"\n";
}

