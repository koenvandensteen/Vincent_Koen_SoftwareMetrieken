module Main

import IO;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import util::Math;
import util::Resources;
import DateTime;
import List;
import Map;
import String;

import Helpers::HelperFunctions;
import Helpers::DataContainers;
import Helpers::TreeBrowser;

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

public void RunVisualisations(){
	println("******* START ANALYZE JabberPoint *********");
	VisualizeProject(|project://JabberPoint|,"JabberPoint");
	println("******* START ANALYZE smallsql *********");
	VisualizeProject(|project://smallsql|,"smallsql");
}

public void VisualizeProject(loc locProject, str projectName){

	//get AST
	M3 m3Project = createM3FromEclipseProject(locProject);
	set[loc] javaFiles = getFilesJava(locProject);
	set[Declaration] ASTDeclarations = createAstsFromFiles(javaFiles, false); 
	
	Workset fullProjectResults;
	Workset noTestResults;
	
	// analyze full project
	fullProjectResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, false);

	// analyze project without testcode
	//noTestResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, true);

	str commonPath = getCommonPath(javaFiles);
	
	aggregateChildren(<locProject + commonPath,<projectName ,"project">>, ASTDeclarations, fullProjectResults);
	
	//visitTree(ASTDeclarations, fullProjectResults);
	//getOveralRatings(fullProjectResults);
	
	//createTreeMap(fullProjectResults);
	//getOveralRatings(fullProjectResults);
	
	
	println("we just got the results with tests included and without!");

}

public Workset AnalyzeProjectV2(set[loc] javaFiles, set[Declaration] ASTDeclarations, bool noTest){	

	// copy input AST
	set[Declaration] origDeclarations = ASTDeclarations; // we make this copy because for some functionality we still need the filtered data
		
	// filter test classes if required
	if(noTest)
		ASTDeclarations = {a | a <- origDeclarations, !isTestClass(a)};
	
	// list to link locs with filenames
	map [loc, str] fileTree = getLocsNames(ASTDeclarations);
	
	/* unit sizes*/
	unitSizeMap = AnalyzeUnitSize(ASTDeclarations); 
	unitSizeRisk = (a : GetUnitSizeRisk(unitSizeMap[a]) | a <- domain(unitSizeMap));
	
	/* unit complexity*/
	unitComplexityMap = AnalyzeUnitComplexity(ASTDeclarations);
	unitComplexityRisk = (a : GetUnitComplexityRisk(unitComplexityMap[a]) | a <- domain(unitComplexityMap));
	
	/* duplication */
	duplicationMap = AnalyzeDuplicationAST(ASTDeclarations); // this map can be printed to display absolute duplication (in loc)
	duplicationPercent = getRelativeRate(unitSizeMap, duplicationMap); // this map can be printed to display relative loc (in % of code which is a duplicate)
	duplicationRating = (a:GetDuplicationRating(duplicationPercent[a]) | a <- domain(duplicationPercent));
		
	/* test coverage */
	unitTestMap = AnalyzeUnitTestMap(origDeclarations);
	unitTestPercent = getRelativeRate(unitComplexityMap, unitTestMap);
	unitTestRating = (a:getTestRating(unitTestPercent[a]) | a <- domain(unitTestPercent));

	//unitTestRisk = (a:getTestRating(unitTestMap));

	// generate overview map
	SIGRating temp = <-3, -3, -3, -3>;
	Workset workset = ();
	for(i <- domain(fileTree)){
		workset += (i:<unitSizeRisk[i], unitComplexityRisk[i], duplicationRating[i], unitTestMap[i]>);
	}

	return workset;
}

public void AnalyzeGlobal(){

	/* total LOC*/
	projectList filteredProject = FilterAllFiles(javaFiles);		
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	// overal rating
	int volumeRating = GetSigRatingLOC(filteredLineCount);
	
	/* unit size */
	unitSizeRating = getRiskFactions(unitSizeMap, unitSizeRisk);
	// overal rating
	int overalUnitSizeRating = GetUnitSizeRating(unitSizeRating["factionModerate"], unitSizeRating["factionHigh"], unitSizeRating["factionExtreme"]);
	
	/* unit complexity */
	unitComplexityRating = getRiskFactions(unitSizeMap, unitComplexityRisk);
	// overal rating
	int overalComplexityRating = GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]);	
	
	/* duplication*/
	// overal rating 
	/* we use the range sum of unit sizes because the overal loc count includes code outside of methods/constructors 
	while that code is not counter for the duplicaiton metric*/
	int overalDuplicationRating = GetDuplicationRating((getRangeSum(getPositives(duplicationMap))/getRangeSum(unitSizeMap))*100);
	
	
	/* test coverage */
	tuple[real v1, real v2] unitTestCoverage = processUnitTestMap(unitTestMap, origDeclarations);;
	// overal rating
	int overalTestCoverageRating = getTestRating(unitTestCoverage.v2);
	
	/* duplication */
	duplicationMap = AnalyzeDuplicationAST(ASTDeclarations); // this map can be printed to display absolute duplication (in loc)
	duplicationPercent = getRelativeRate(unitSizeMap, duplicationMap); // this map can be printed to display relative loc (in % of code which is a duplicate)
	duplicationRating = (a:GetDuplicationRating(duplicationPercent[a]) | a <- domain(duplicationPercent));
	// overal rating 
	/* we use the range sum of unit sizes because the overal loc count includes code outside of methods/constructors 
	while that code is not counter for the duplicaiton metric*/
	int overalDuplicationRating = GetDuplicationRating((getRangeSum(getPositives(duplicationMap))/getRangeSum(unitSizeMap))*100);

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
	
	int overalUnitSizeRating = GetUnitSizeRating(unitSizeRating["factionModerate"], unitSizeRating["factionHigh"], unitSizeRating["factionExtreme"]);
	
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
	int duplicatedLines = getRangeSum(getPositives(AnalyzeDuplicationAST(ASTDeclarations)));
	totalReport+=PrintAndReturnString("total lines duplicated: <duplicatedLines>");
	num duplicatePercentage = (duplicatedLines/(filteredLineCount/100.000));
	totalReport+=PrintAndReturnString("total lines duplicated percentage: <round(duplicatePercentage,0.01)>%");
	int duplicationRating = GetDuplicationRating(duplicatePercentage);
	totalReport+=PrintAndReturnString("**** duplication SIG-rating: <transFormSIG(duplicationRating)>");
	println("\n");
	
	/*
	//unit Test Rating metric
	*/	
	unitTestMap = AnalyzeUnitTestMap(ASTDeclarations);
	tuple[real v1, real v2] unitTestCoverage = processUnitTestMap(unitTestMap, ASTDeclarations);
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
	
	totalReport+=PrintAndReturnString("ISO 9126 maintainability chart");
	totalReport+=PrintAndReturnString("______________________________");
	totalReport+=PrintAndReturnString("     | V | U | D | U | U || T ");	
	totalReport+=PrintAndReturnString("     | O | N | U | N | N || O ");	
	totalReport+=PrintAndReturnString("     | L | T | P | T | T || T ");
	totalReport+=PrintAndReturnString("     | U | C | L | S | T || A ");
	totalReport+=PrintAndReturnString("     | M | M | I | I | S || L ");
	totalReport+=PrintAndReturnString("     | E | X | C | Z | T || * ");
	totalReport+=PrintAndReturnString("_____|___|___|___|___|___||___");
	totalReport+=PrintAndReturnString("ANALY|<transFormSIG(volumeRating)> |   |<transFormSIG(duplicationRating)> |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.analysability)>");
	totalReport+=PrintAndReturnString("CHANG|   |<transFormSIG(overalComplexityRating)> |<transFormSIG(duplicationRating)> |   |   ||<transFormSIG(maintabilityRating.changeability)>");
	totalReport+=PrintAndReturnString("STABI|   |   |   |   |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.stability)>");
	totalReport+=PrintAndReturnString("TESTA|   |<transFormSIG(overalComplexityRating)> |   |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.testability)>");
	totalReport+=PrintAndReturnString("_____|___|___|___|___|___||___");
	totalReport+=PrintAndReturnString("TOTAL|   |   |   |   |   ||<transFormSIG(GetTotalSIGRating(maintabilityRating))> ");
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

