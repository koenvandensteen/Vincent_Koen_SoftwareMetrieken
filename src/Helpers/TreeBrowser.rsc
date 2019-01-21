module Helpers::TreeBrowser

import lang::java::m3::AST;
import Map;
import IO;

import Helpers::DataContainers;

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
		
		println(tm);
		return tm;
	}
	
	for(i <- domain(children.objectMap)){
		result = aggregateChildren(<i, children.objectMap[i]>, children.newAST, workset);
		branches  += result; // branches are where the recursive calculation takes place in this method
		ratingList += result.rating; // we store the ratings of deeper objects seperately for easy calculation of a "global" sig
	}
	
	//we determine one generalised rating for all elements
	currentSig = aggregateSigList(ratingList);
	
	return treeMap(input.currentLoc, input.dataIn, currentSig, branches);
}

// below class gets the correct type of children. Unfortunately at the moment the entire AST is searched over and over
// to increase efficiency the AST can be cut down to the relevant part only, 
// previsions are made for (an AST is returned however at the moment this is the full AST) this and work on this field is a next improvement
public tuple[map[loc, AnalyzedObject], set[Declaration]] getChildren(loc current, str inType, set[Declaration] AST){

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

public map[loc, AnalyzedObject] getPackageMap(loc current, AST){

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
public map[loc, AnalyzedObject] getClassMap(loc current, AST){

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

public map[loc, AnalyzedObject] getMethodMap(loc current, AST){

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

private SIGRating aggregateSigList(ratingList){
	println("placeholder");
	return <-3, -3, -3, -3>;
}