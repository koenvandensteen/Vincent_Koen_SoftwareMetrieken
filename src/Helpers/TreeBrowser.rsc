module Helpers::TreeBrowser

import lang::java::m3::AST;
import util::Math;
import Map;
import List;
import IO;

import Helpers::DataContainers;
import Agregation::SIGRating;

public TreeMap aggregateChildren(tuple[loc currentLoc, AnalyzedObject dataIn] input, set[Declaration] AST, Workset workset){
	
	list[TreeMap] branches = [];
	TreeMap tm;
	TreeMap result;
	list[SIGRating] ratingList = [];

	
	list[SIGRating] retVal = [];
	tuple[map[loc, AnalyzedObject] objectMap, set[Declaration] newAST] children = <(), AST>;
	SIGRating currentSig = <-3, -3, -3, -3>;

	children = getChildren(input.currentLoc, input.dataIn.objType, AST);
	
	// some projects are made without packages, we check if we are in the "package' level, if there are no packages we go to the next level
	if(input.dataIn.objType == "project" && size(children.objectMap) <= 1)
		children = getChildren(input.currentLoc, "package", AST);
	
	// this is the base case of our recursive approach: the method level
	if(size(children.objectMap) == 0 && input.dataIn.objType == "method"){
	
		if(input.currentLoc in workset)
			currentSig = workset[input.currentLoc];
		
		tm = treeMap(input.currentLoc, input.dataIn, currentSig, []);
		
		//debug	
		//println(tm);
		return tm;
	}
	
	for(i <- domain(children.objectMap)){
		result = aggregateChildren(<i, children.objectMap[i]>, children.newAST, workset);
		branches  += result; // branches are where the recursive calculation takes place in this method
		ratingList += result.rating; // we store the ratings of deeper objects seperately for easy calculation of a "global" sig
	}
	
	//we determine one generalised rating for all elements
	currentSig = aggregateSigList(ratingList);
	
	//debug
	//println("<input.currentLoc>, <input.dataIn>, <currentSig>");
	
	return treeMap(input.currentLoc, input.dataIn, currentSig, branches);
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
			//if(size(packageMap) > 0)
				return <packageMap, AST>;
			//else
			//	return <(():"package"), AST>;
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

// update to tuple[map[str, str], set[Declaration]]
private map[loc, AnalyzedObject] getClassMap(loc current, AST){

	map[loc, AnalyzedObject] classMap = ();

	visit(AST){
		case c: \class(str name, _, _, _):{
				if((c.src).path == (current+(name+".java")).path){
					classMap += (c.src:<name,"class">);
					}
			}
	}
	
	//for(i <- domain(classMap)){
	//	println("class <i>");
	//}
	
	return classMap;
}

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
private SIGRating aggregateSigList(list[SIGRating] ratingList){

	factionsLoc = getOccurences(ratingList, 0);
	factionsCompl = getOccurences(ratingList, 0);
	factionsDup = getOccurences(ratingList, 0);
	factionsTest = getOccurences(ratingList, 0);
	
	// next rating for size needs factions of mid (0), high(-1) and extreme(-2)
	int nextLocRating = GetUnitSizeRating(factionsLoc[0], factionsLoc[-1], factionsLoc[-2]);
	// next rating for complexity needs factions of mid (0), high(-1) and extreme(-2)
	int nextCompRating = GetUnitComplexityRating(factionsCompl[0], factionsCompl[-1], factionsCompl[-2]);
	// next rating for duplication needs ???
	println("to do: agregate duplication ratings");
	int nextDupRating = -3;
	//
	println("to do: agregate test coverage ratings");
	int nextTestRating = -3;

	println("placeholder");
	return <nextLocRating, nextCompRating, nextDupRating, nextTestRating>;
}

private map[int, real] getOccurences(list[SIGRating] ratingList, int target){
	
	map[int rating, int occurences] resMap = ();
	resMap += (2:0);
	resMap += (1:0);
	resMap += (0:0);
	resMap += (-1:0);
	resMap += (-2:0);
	resMap += (-3:0);
	
	map[int, real] retVal = ();
	
	//map[str targetType, map[int, int]] retVal = ();
	//retVal

	// count occurences
	for(i <- ratingList){
		//println("full <i>");
		//println("target <i.uLoc>");
		//println("target <i[0]>");
		resMap[i[target]] += 1; 
	}
	
	// get relative amount
	int mapSize = size(ratingList);
	
	for(i <- domain(resMap)){
		retVal += (i:toReal(resMap[i])/mapSize);
	}
	
	//println("count <mapSize>");
	//println(resMap);
	//println(retVal);
	
	
	return(retVal);

}

