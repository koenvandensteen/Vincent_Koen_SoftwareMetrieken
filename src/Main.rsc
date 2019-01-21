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
	
	tuple[map[loc, str], int, map[loc, int], map[loc, int], map[loc, int], map[loc, int]] fullProjectResults;
	tuple[map[loc, str], int, map[loc, int], map[loc, int], map[loc, int], map[loc, int]] noTestResults;
	
	// analyze full project
	fullProjectResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, false);

	// analyze project without testcode
	//noTestResults = AnalyzeProjectV2(javaFiles, ASTDeclarations, true);

	str commonPath = getCommonPath(javaFiles);
	
	aggregateChildren(<locProject + commonPath, "project">, ASTDeclarations, fullProjectResults);
	
	//visitTree(ASTDeclarations, fullProjectResults);
	//getOveralRatings(fullProjectResults);
	
	//createTreeMap(fullProjectResults);
	//getOveralRatings(fullProjectResults);
	
	
	println("we just got the results with tests included and without!");

}



public int aggregateChildren(tuple[loc current, str inType] input, set[Declaration] AST, tuple[map[loc, str] tree, int lines, map[loc, int] uLoc, map[loc, int] uComp, map[loc, int] uDup, map[loc, int] uTest] workSet){
	
	int retVal = 0;
	tuple[map[str, str] child, set[Declaration] newAST] children = <(), AST>;
	
	children = getChildren(input.current, input.inType, AST);
	
	// some projects are made without packages, we check if we are in the "package' level, if there are no packages we go to the next level
	if(input.inType == "project" && size(children.child) <= 1)
		children = getChildren(input.current, "package", AST);
	
	if(size(children.child) == 0){
		println("todo, get one set of sig metrics");
		return 1;
	}
	
	retVal = 0;
	
	for(i <- domain(children.child)){
		println(input.current+i);
		retVal  += aggregateChildren(<input.current+i, children.child[i]>, children.newAST, workSet);
		// above can return sig metrics of a deeper level, new sig metrics should be established based on that
	}
	
	println("todo: proces matrix retVal");
	
	return retVal;
}

// below class gets the correct type of children. Unfortunately at the moment the entire AST is searched over and over
// to increase efficiency the AST can be cut down to the relevant part only, 
// previsions are made for (an AST is returned however at the moment this is the full AST) this and work on this field is a next improvement
public tuple[map[str, str], set[Declaration]] getChildren(loc current, str inType, set[Declaration] AST){

	map[str, str] packageMap = ();
	map[str, str] classMap = ();
	map[str, str] methodMap = ();
	
	switch(inType){
		// projects have packages as children (if any)
		case /project/:{
			packageMap = getPackageMap(current, AST);
			if(size(packageMap) > 0)
				return <packageMap, AST>;
			else
				return <("":"package"), AST>;
		}
		// packages have classes as children
		case /package/:{
			classMap = getClassMap(current, AST);
				return <classMap, AST>;
		}
		// classes have methods as children
		case /class/:{
			methodMap = getMethodMap(current, AST);
				return <methodMap, AST>;
		}
		// methods do not have children
		case /method/:{
			return <(), AST>;
		}
	}
	
	// should never be reached!
	return <(), AST>;

}

public map[str, str] getPackageMap(loc current, AST){

	map[str, str] packageMap = ();

	visit(AST){
		case \package(Declaration parentPackage, str name):{
			if(! (name in packageMap))
				packageMap += (name:"package");		
			}
	}
	
	return packageMap;
}

// update to tuple[map[str, str], set[Declaration]]
public map[str, str] getClassMap(loc current, AST){

	map[str, str] classMap = ();

	visit(AST){
		case c: \class(str name, _, _, _):{
				if((c.src).path == (current+(name+".java")).path)
					classMap += (name+".java":"class");
			}
	}
	
	return classMap;
}

public map[str, str] getMethodMap(loc current, AST){

	map[str, str] methodMap = ();

	visit(AST){
			case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):{
				if((m.src).path == (current.path))
					methodMap += (name:"method");
	    	}
	    	case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):{
	    		if((m.src).path == (current.path))
					methodMap += (name:"method");
	    	}
	    	case m: \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):{	
		    	if((m.src).path == (current.path))
					methodMap += (name:"method");
			}
		}
		
		
	
	return methodMap;
}


public void visitTree(set[Declaration] AST, tuple[map[loc, str] tree, int lines, map[loc, int] uLoc, map[loc, int] uComp, map[loc, int] uDup, map[loc, int] uTest] workSet){

	
	//map[loc, list[Declaration]] classMap = ();
	list[str] classList = [];
	list[str] methodList = []; // includes constructors!

	// complete lists of all packages (if any) and classes
	visit(AST){
		case \package(Declaration parentPackage, str name):{
			if(! (name in packageList))
				packageList += name;		
			}
		case c: \class(str name, list[Type] extends, list[Type] implements, list[Declaration] body):
			//classMap += (c.src:body);
			classList += name;
	}
	
	// we loop from the atomic method to the total project
	// method is already known
	// next step up are the classes
	for(i <- classList){
		println(i);
	}
	
	
	
	
	// loop all classes
	/* requires the visit(ast) above to store the bodies
	int testVar;
	
	for(i <- domain(classMap)){
		visit(classMap[i]){
			case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):
				methodList += m.src;
	    	case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):
	    		methodList += m.src;
	    	case m: \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):	
				methodList += m.src;
		}
		
		testVar = 0;
		for(j <- domain(workSet.tree)){
			if(j in methodList){
				//println("<j> has <workSet.uLoc[j]> lines of code");
				testVar += workSet.uLoc[j];
			}
		}
		//println("so class <i> has <testVar> lines");
	}
	*/
	
}


/*
public void createTreeMap(tuple[map[loc, str] treeMap, int tLoc, map[loc, int] uSize, map[loc, int] uCompl, map[loc, int] uDup, map[loc, int] uTest] workSet){
	
	for(i <- domain(workSet.treeMap)){
		println(i);
		1/0;
	} 
	
	
}

public tuple[str, loc, SigRating, Content] createBranch(loc input){

	str name;
	str location;
	SigRating sig;
	Content cont;	
	list[loc] stack = [];
	
	tuple[str, loc, SigRating, Content] retVal;
	
	// final "leaf", base case
	if(isLeaf(input)){
		println("leaf");
		name = "aF";
		location = "lF";
		sig = [1, 1, 1, 1];
		return <name, location, sig, cont>;
	}
	
	//push root to stack
	stack += input;
	
	// get children of current node
	children = ();
	
	//process children
	while(size(stack)>0){
		//pop the first item and print it
		tuple[loc head, list[loc] tail] current = pop(stack);
		// get current data
		retVal = <"a", toString(head), [1, 1, 1, 1], tail>;
		
		// add tail to stack
		if(size(children > 0)){
			for(i <- children){
				push(i, tail);	
			}
		}
	}

	return <name, location, sig, cont>;
}

public list[loc] getChildren(loc input){

}

public bool isLeaf(){
	return false;
}
*/

public tuple[map[loc, str], int, map[loc, int], map[loc, int], map[loc, int], map[loc, int]]  AnalyzeProjectV2(set[loc] javaFiles, set[Declaration] ASTDeclarations, bool noTest){	

	// copy input AST
	set[Declaration] origDeclarations = ASTDeclarations; // we make this copy because for some functionality we still need the filtered data
		
	// filter test classes if required
	if(noTest)
		ASTDeclarations = {a | a <- origDeclarations, !isTestClass(a)};
	
	// list to link locs with filenames
	map [loc, str] fileTree = getLocsNames(ASTDeclarations);

	/* total LOC*/
	projectList filteredProject = FilterAllFiles(javaFiles);		
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	// overal rating
	int volumeRating = GetSigRatingLOC(filteredLineCount);
	
	/* unit sizes*/
	unitSizeMap = AnalyzeUnitSize(ASTDeclarations); 
	unitSizeRisk = (a : GetUnitSizeRisk(unitSizeMap[a]) | a <- domain(unitSizeMap));
	unitSizeRating = getRiskFactions(unitSizeMap, unitSizeRisk);
	// overal rating
	int overalUnitSizeRating = GetUnitSizeRating(unitSizeRating["factionModerate"], unitSizeRating["factionHigh"], unitSizeRating["factionExtreme"]);
	
	/* unit complexity*/
	unitComplexityMap = AnalyzeUnitComplexity(ASTDeclarations);
	unitComplexityRisk = (a : GetUnitComplexityRisk(unitComplexityMap[a]) | a <- domain(unitComplexityMap));
	unitComplexityRating = getRiskFactions(unitSizeMap, unitComplexityRisk);
	// overal rating
	int overalComplexityRating = GetUnitComplexityRating(unitComplexityRating["factionModerate"], unitComplexityRating["factionHigh"], unitComplexityRating["factionExtreme"]);	
	
	/* duplication */
	duplicationMap = AnalyzeDuplicationAST(ASTDeclarations); // this map can be printed to display absolute duplication (in loc)
	duplicationPercent = getRelativeRate(unitSizeMap, duplicationMap); // this map can be printed to display relative loc (in % of code which is a duplicate)
	duplicationRating = (a:GetDuplicationRating(duplicationPercent[a]) | a <- domain(duplicationPercent));
	// overal rating 
	/* we use the range sum of unit sizes because the overal loc count includes code outside of methods/constructors 
	while that code is not counter for the duplicaiton metric*/
	int overalDuplicationRating = GetDuplicationRating((getRangeSum(getPositives(duplicationMap))/getRangeSum(unitSizeMap))*100);
	
	/* test coverage */
	unitTestMap = AnalyzeUnitTestMap(origDeclarations);
	tuple[real v1, real v2] unitTestCoverage = processUnitTestMap(unitTestMap, origDeclarations);;
	// overal rating
	int overalTestCoverageRating = getTestRating(unitTestCoverage.v2);

	// compile map
	//tuple [int uSizeAbs, int uSizeRel] hulpTuple;
	//map[loc, tuple [int uSizeAbs, int uSizeRel, int uComplAbs, int uComplRel, int uDuplAbs, int uDuplRel, int uTstCoverage]] visuMap =();
	/* map structure: 
	 - loc
	 - total lines of code
	 - unit size absolute
	 - unit size relative
	 - unit compelxity absolute
	 - unit complexity relative
	 - unit duplication absolute
	 - unit duplication relative
	 - unit test coverage
	 in case of the 'absolute' variables these will represent the raw results. Displaying this will enable to see what the root causes are of a (bad) sig rating
	 -> this means e.g. if all sig ratings are "++" all items can be colored green, there is no scaling or some similar process
	 the 'relative' versions on the other hand will stretch the results based on the worst and best performers
	 -> this means e.g. if all sig ratings are "++" the largest ones (= closest to a lower qualification) will be marked as red/orange/yellow . This enables to see which factors are the weakest
	 test coverage only has one version
	 -> test coverage is a bool (stored as int): 0 = method not tested, 1 = method tested
	*/
	
	// overal map is generated based on the domain of the filetree map for now
	//for(i <- domain(fileTree)){		
	//	hulpTuple = <unitSizeMap[i], unitSizeRisk[i], unitComplexityMap[i], unitComplexityRisk[i], duplicationMap[i], duplicationRating[i], unitTestMap[i]>;
	//	visuMap += (i:hulpTuple);
	//}
	//
	//println("resultaten - return ook total loc en andere **algemene** sig resultaten, als kleur?"); // bv door: overalVars = <filteredLineCount, complexityRating>;
	//tuple [int totalSize, real uSizeRate, real uComplRate] overalScores;

	return <fileTree, filteredLineCount, unitSizeMap, unitComplexityMap, duplicationMap, unitTestMap>;
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

