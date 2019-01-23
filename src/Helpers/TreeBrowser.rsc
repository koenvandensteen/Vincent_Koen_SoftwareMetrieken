module Helpers::TreeBrowser

import lang::java::m3::AST;
import util::Math;
import Map;
import List;
import IO;

import Helpers::DataContainers;
import Helpers::HelperFunctions;
import Agregation::SIGRating;

public BrowsableMap aggregateChildren(tuple[loc location, AnalyzedObject objData] root, set[Declaration] AST, Workset workset){
	
	list[SIGRating] retVal = [];
	list[SIGRating] ratingList = [];
	list[GlobalVars] globalList = [];
	map[tuple[loc, str], BrowsableMap] branches = ();
	BrowsableMap projectTree;
	BrowsableMap result;
	tuple[map[loc, AnalyzedObject] objectMap, set[Declaration] newAST] children = <(), AST>;
	
	// set default values
	SIGRating currentSig = <-3, -3, -3, -3>;
	GlobalVars currentGlobal = <0.0, 0.0, 0>;
	
	// get the sub-objects of the current object
	children = getChildren(root.location, root.objData.objType, AST);
	
	// some projects are made without packages, we check if we are in the "package' level, if there are no packages we go to the next level
	if(root.objData.objType == "project" && size(children.objectMap) <= 1)
		children = getChildren(root.location, "package", AST);
	
	// this is the base case of our recursive approach: the method level
	if(size(children.objectMap) == 0 && root.objData.objType == "method"){	
		if(root.location in workset){
			currentSig = workset[root.location].wRating;
			currentGlobal = workset[root.location].wGlobal;	
		}
		
		projectTree = browsableMap(root.location, root.objData, currentSig, currentGlobal, ());
		
		//debug	
		//println("<root.location>, <root.objData>, <currentSig>, <currentGlobal>");
		return projectTree;
	}
	
	// recursive step, call this function for all the results
	for(i <- domain(children.objectMap)){
		result = aggregateChildren(<i, children.objectMap[i]>, children.newAST, workset);
		branches  += (<root.location, root.objData.objName>:result); // branches are where the recursive calculation takes place in this method
		ratingList += result.rating; // we store the ratings of deeper objects seperately for easy calculation of a "global" sig
		globalList += result.globalVars;
	}
	
	//we determine one generalised rating for all elements, the coverage is recovered seperately to keep the "currentSig" var clean
	currentSig = aggregateSigList(ratingList, globalList);
	currentGlobal = getNewGlobalVars(globalList, root.location, root.objData.objType);
	
	//debug
	//if(root.objData.objType == "class")
	//if(root.objData.objType == "package")
	//if(root.objData.objType == "project")
	//if(root.objData.objType == "project" || root.objData.objType == "package")
		println("<root.location>, <root.objData>, <currentSig>, <currentGlobal>");
	
	return browsableMap(root.location, root.objData, currentSig, currentGlobal, branches);
}

// below class gets the correct type of children. Unfortunately at the moment the entire AST is searched over and over
// to increase efficiency the AST can be cut down to the relevant part only, 
// previsions are made for (an AST is returned however at the moment this is the full AST) this and work on this field is a next improvement
private tuple[map[loc, AnalyzedObject], set[Declaration]] getChildren(loc current, str inType, set[Declaration] AST){

	map[loc, AnalyzedObject] packageMap = ();
	map[loc, AnalyzedObject] classMap = ();
	map[loc, AnalyzedObject] methodMap = ();
	
	switch(inType){
		// projects have packages as children (if any)
		case /project/:{
			packageMap = getPackageMap(current, AST);
				return <packageMap, AST>;
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

//returns all packages for a location
private map[loc, AnalyzedObject] getPackageMap(loc current, AST){

	map[loc, AnalyzedObject] packageMap = ();
	list[str] packageList = [];

	visit(AST){
		case \package(Declaration parentPackage, str name):{
			if(! (name in packageList))
				packageList += [name];	
				packageMap += ((current+name):<name,"package">);	
			}
	}
	
	return packageMap;
}

// returns a list of classes for a location
private map[loc, AnalyzedObject] getClassMap(loc current, AST){

	map[loc, AnalyzedObject] classMap = ();

	visit(AST){
		case c: \class(str name, _, _, _):{
				if((c.src).path == (current+(name+".java")).path){
					classMap += (c.src:<name,"class">);
					}
			}
	}
	
	return classMap;
}

// gets all methods in a location
private map[loc, AnalyzedObject] getMethodMap(loc current, AST){

	map[loc, AnalyzedObject] methodMap = ();
	
	loc hulp = current;

	visit(AST){
			case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):{
				if((m.src.path) == (current.path))
					methodMap += (current(m.src.offset, m.src.length, m.src.begin, m.src.end):<name, "method">);	
	    	}
	    	case m: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions):{
				if((m.src.path) == (current.path))
					methodMap += (current(m.src.offset, m.src.length, m.src.begin, m.src.end):<name, "method">);
	    	}
	    	case m: \constructor(str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl):{	
				if((m.src.path) == (current.path))
					methodMap += (current(m.src.offset, m.src.length, m.src.begin, m.src.end):<name, "method">);
			}
		}
	
	return methodMap;
}


//gets the overal rating of a component based on the risk factions of it's subcomponents
private SIGRating aggregateSigList(list[SIGRating] ratingList, list[GlobalVars] globalList){

	//get new ratings
	factionsLoc = getOccurences(ratingList, 0);
	factionsCompl = getOccurences(ratingList, 1);
	percentageDup = getNewGlobalVars(globalList).Dup;
	percentageTest = getNewGlobalVars(globalList).Cov;
	
	// for each metric, get the best current rating as the new rating cannot be higher than this
	//maxRatings = getMaxSig(ratingList);
	
	// next rating for size needs factions of mid (0), high(-1) and extreme(-2)
	int nextLocRating = GetUnitSizeRating(factionsLoc[0], factionsLoc[-1], factionsLoc[-2]);
	//int nextLocRating = max(GetUnitSizeRating(factionsLoc[0], factionsLoc[-1], factionsLoc[-2]),maxRatings.uLoc);
	// next rating for complexity needs factions of mid (0), high(-1) and extreme(-2)
	int nextCompRating = GetUnitComplexityRating(factionsCompl[0], factionsCompl[-1], factionsCompl[-2]);
	//int nextCompRating = max(GetUnitComplexityRating(factionsCompl[0], factionsCompl[-1], factionsCompl[-2]),maxRatings.uDup);
	// next rating for duplication needs a percentage of duplication, we achieve this by averaging the list of earlier percentages
	int nextDupRating = GetDuplicationRating(percentageDup);
	//int nextDupRating = max(GetDuplicationRating(percentageDup),maxRatings.uDup);
	// next rating for test coverage needs a percentage of coverage, we achieve this by averaging the list of earlier percentages
	int nextTestRating = GetTestRating(percentageTest);
	//int nextTestRating = max(GetTestRating(percentageTest),maxRatings.uTest);

	return <nextLocRating, nextCompRating, nextDupRating, nextTestRating>;
}

// gets the maximum ratings for each metric in a SIGRating object
private SIGRating getMaxSig(list[SIGRating] ratingList){
	maxLoc = max(ratingList.uLoc);
	maxComp = max(ratingList.uComp);
	maxDup = max(ratingList.uDup);
	maxTest = max(ratingList.uTest);
	
	return <maxLoc, maxComp, maxDup, maxTest>;
}

// calculates how often a specific value for a metric occurs in a list of ratings relative to the total amount of ratings
private map[int, real] getOccurences(list[SIGRating] ratingList, int target){
	
	map[int rating, int occurences] resMap = ();
	resMap += (2:0);
	resMap += (1:0);
	resMap += (0:0);
	resMap += (-1:0);
	resMap += (-2:0);
	resMap += (-3:0);
	
	map[int, real] retVal = ();
	
		
	// get the size of the map to find the relative amounts later on
	int mapSize = size(ratingList);
	
	// during testing a bug became clear when a package is nested in another package
	// until we arive at the point to fix this we ignor the problem bij returning an empty map
	if(mapSize == 0){
		retVal += (2:0.0);
		retVal += (1:0.0);
		retVal += (0:0.0);
		retVal += (-1:0.0);
		retVal += (-2:0.0);
		retVal += (-3:0.0);
		return (retVal);

	}

	// count occurences
	for(i <- ratingList){
		resMap[i[target]] += 1; 
	}

	// average out results
	for(i <- domain(resMap)){
		retVal += (i:toReal(resMap[i])/mapSize);
	}
	
	//debug
	//println(retVal);
	
	return(retVal);

}

// calculates the new duplication count, test coverage and global line count based on a list of these values for smaller code units
// (e.g. when this is calculated for a class, all methods are taken into account)
private tuple[real Dup, real Cov, int codeLines] getNewGlobalVars(list[tuple[real DupIn, real CovIn, int LinesIn]] valIn){
	int tupSize = 0;
	real dup = 0.0;
	real cov = 0.0;
	int lines = 0;
	
	for(i <- valIn){
		dup += i.DupIn;
		cov += i.CovIn;
		lines += i.LinesIn;
	}
	
	tupSize = size(valIn);
	
	// during testing a bug became clear when a package is nested in another package
	// until we arive at the point to fix this we ignor the problem bij returning zero values
	if(tupSize == 0)
		return <-1.0, -1.0, -1>;
	
	return <dup/tupSize, cov/tupSize, lines>;
}

// overloaded version of previous method for when location is known (more accurate) and the object type is a class (otherwise not all files may be read)
private tuple[real Dup, real Cov, int codeLines] getNewGlobalVars(list[tuple[real DupIn, real CovIn, int LinesIn]] valIn, loc location, str objType){
	// get other vars
	tuple[real Dup, real Cov, int CL] retVal = getNewGlobalVars(valIn);
	// single out code line count of original method
	int codeLines = retVal.CL;
	
	// overwrite loc only if the current object is a class
	if(objType == "class")
		codeLines = size(FilterSingleFile(location)); // get loc
	
	return <retVal.Dup, retVal.Cov, codeLines>;
}
