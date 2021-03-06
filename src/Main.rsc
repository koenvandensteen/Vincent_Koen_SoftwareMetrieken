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

import View::TreeView;

public void RunTestProgram(){
	// run test module
	println("******* CHECK PROGRAM VALIDITY *********");
	TestAll();
	println();
	// run main with test project
	println("******* START ANALYZE TEST PROJECT *********");
	AnalyzeProject(|project://SimpleJavaDemo|,"Test Project");
}

// test class, for manual selection of one project to speed up rendering
public void TestVisualisations(int i){
	
	map[tuple[str name, bool junit] key, BrowsableMap mapData] allGuiData = ();

	if(i == 1 || i == 4){
		println("******* START ANALYZE JabberPoint *********");
		allGuiData += createProjectVisualisations(|project://Jabberpoint|,"Jabberpoint");
	}
	if(i == 2 || i == 4){
		println("******* START ANALYZE smallsql *********");
		allGuiData += createProjectVisualisations(|project://smallsql|,"smallsql");
	}
	if(i == 3 || i == 4){
		println("******* START ANALYZE JabberPoint *********");
		allGuiData += createProjectVisualisations(|project://hsqldb|,"hsqldb");
	}
	
	ShowGUI(allGuiData);
}

// main function for gathering, and displaying, project data
public void runVisualisation(){

	map[tuple[str name, bool junit] key, BrowsableMap mapData] allGuiData = ();

	println("******* START ANALYZE JabberPoint *********");
	allGuiData += createProjectVisualisations(|project://JabberPoint|,"Jabberpoint");
	println("******* START ANALYZE smallsql *********");
	allGuiData += createProjectVisualisations(|project://smallsql|,"smallsql");
	println("******* START ANALYZE hsqldb *********");
	allGuiData += AnalyzeProject(|project://hsqldb|,"hsqldb");
	
	// open gui
	ShowGUI(allGuiData);
}

// creates data in format for visualisation
private map[tuple[str name, bool junit] key, BrowsableMap mapData] createProjectVisualisations(loc locProject, str projectName){
	
	Workset fullProjectResults;
	Workset noTestResults;

	map[tuple[str name, bool junit] key, BrowsableMap mapData] guiData = ();

	// start timer
	startMoment = now();	
	//get AST
	M3 m3Project = createM3FromEclipseProject(locProject);
	set[loc] javaFiles = getFilesJava(locProject);
	set[Declaration] ASTDeclarations = createAstsFromFiles(javaFiles, false); 
	// get common file path
	str commonPath = getCommonPath(javaFiles);

	// analyze full project, including junit
	fullProjectResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, false);	
	// end timer for analasys
	endMoment = now();
	// get data in tree map format
	BrowsableMap endResult = aggregateChildren(<locProject + commonPath,<projectName ,"project">>, ASTDeclarations, fullProjectResults);
	// add map to results
	guiData += (<projectName, false>: endResult);
	// print out the report
	CreateReport(endResult, startMoment, endMoment, false);
	
	// analyze full project, excluding junit
	fullProjectResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, true);	
	// get data in tree map format
	endResult = aggregateChildren(<locProject + commonPath,<projectName ,"project">>, ASTDeclarations, fullProjectResults);
	// add map to results
	guiData += (<projectName, true>: endResult);
	// print out the report
	CreateReport(endResult, startMoment, endMoment, true);
	
	return(guiData);
}

// returns analysis of a project
private Workset AnalyzeProjectV2(set[loc] javaFiles, set[Declaration] ASTDeclarations, bool noTest){	

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
	unitTestRating = (a:GetTestRating(unitTestPercent[a]) | a <- domain(unitTestPercent));

	//unitTestRisk = (a:GetTestRating(unitTestMap));

	// generate overview map
	SIGRating tempSig = <-3, -3, -3, -3>;
	GlobalVars tempGlob = <0.0, 0.0, 0>;
	Workset workset = ();
	for(i <- domain(fileTree)){
		tempSig = <unitSizeRisk[i], unitComplexityRisk[i], duplicationRating[i], unitTestMap[i]>;
		tempGlob = <duplicationPercent[i], unitTestPercent[i], unitSizeMap[i]>;
		workset += (i:<tempSig,tempGlob>);
	}

	return workset;
}

// creates a report
private void CreateReport(BrowsableMap proj, datetime startMoment, datetime endMoment, bool noTest)
{
	list[str] totalReport = [];
	
	// time management 
	executionDuration = createDuration(startMoment,endMoment);	
	totalReport+=("**** analasys started at: <startMoment>");
	
	/*
	//LOC Metric
	*/
	volumeRating = GetSigRatingLOC(proj.globalVars.lineCount);
	totalReport+=("total lines filtered: <proj.globalVars.lineCount>");
	totalReport+=("**** line count SIG-rating: <volumeRating>");
	
	/*
	//unitSizeRating Metric
	*/	
	overalUnitSizeRating = proj.rating.uLoc;
	totalReport+=("**** unit size SIG-rating: <overalUnitSizeRating>");
	
	/*
	//Unit Complexity Metric
	*/
	overalComplexityRating = proj.rating.uComp;
	totalReport+=("**** unit complexity SIG-rating: <overalComplexityRating>");
	
	/*
	//duplication Metric
	*/
	duplicationRating = proj.rating.uDup;
	totalReport+=("**** duplication SIG-rating: <duplicationRating>");
	
	/*
	//unit Test Rating metric
	*/	
	unitTestingRating = proj.rating.uTest;
	totalReport+=("**** test coverage SIG-rating: <unitTestingRating>");
	
	/*
	//Overal agregation of data
	*/			
	maintabilityRating = GetMaintabilityRating(volumeRating, overalComplexityRating, duplicationRating, overalUnitSizeRating, unitTestingRating);
	totalReport+=("**** analysability: <transFormSIG(maintabilityRating.analysability)>");
	totalReport+=("**** changeability: <transFormSIG(maintabilityRating.changeability)>");
	totalReport+=("**** stability: <transFormSIG(maintabilityRating.stability)>");
	totalReport+=("**** testability: <transFormSIG(maintabilityRating.testability)>");
	totalReport+=("<proj.location> has been analyzed and receives an overal rating of: <transFormSIG(GetTotalSIGRating(maintabilityRating))>");
	
	totalReport+=("\n");
	totalReport+=("\n");
	
	totalReport+=("ISO 9126 maintainability chart");
	totalReport+=("______________________________");
	totalReport+=("     | V | U | D | U | U || T ");	
	totalReport+=("     | O | N | U | N | N || O ");	
	totalReport+=("     | L | T | P | T | T || T ");
	totalReport+=("     | U | C | L | S | T || A ");
	totalReport+=("     | M | M | I | I | S || L ");
	totalReport+=("     | E | X | C | Z | T || * ");
	totalReport+=("_____|___|___|___|___|___||___");
	totalReport+=("ANALY|<transFormSIG(volumeRating)> |   |<transFormSIG(duplicationRating)> |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.analysability)>");
	totalReport+=("CHANG|   |<transFormSIG(overalComplexityRating)> |<transFormSIG(duplicationRating)> |   |   ||<transFormSIG(maintabilityRating.changeability)>");
	totalReport+=("STABI|   |   |   |   |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.stability)>");
	totalReport+=("TESTA|   |<transFormSIG(overalComplexityRating)> |   |<transFormSIG(overalUnitSizeRating)> |<transFormSIG(unitTestingRating)> ||<transFormSIG(maintabilityRating.testability)>");
	totalReport+=("_____|___|___|___|___|___||___");
	totalReport+=("TOTAL|   |   |   |   |   ||<transFormSIG(GetTotalSIGRating(maintabilityRating))> ");
	totalReport+=("\n");
	totalReport+=("\n");
	
	
	totalReport+=("**** analys ended at: <now()> and took <executionDuration.minutes> minutes <executionDuration.seconds> seconds <executionDuration.milliseconds> milliseconds \n\n\n\n\n");
			
	loc writeDestination = |project://SoftwareEvolution/|;
	
	if(noTest){
		writeDestination.uri += "/<proj.abj.objName>_metrics_no_Junit.txt";
	}
	else{
		writeDestination.uri += "/<proj.abj.objName>_metrics.txt";
	}
	
	writeFile(writeDestination, totalReport);
}
