module Metrics::Duplication

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import util::Math;

import Helpers::HelperFunctions;
import ListRelation;
import Helpers::DataContainers;


int blockSize = 6;

//public map[loc, int] countDupsPerLoc(set[Declaration] decls){
public map[loc, int]  AnalyzeDuplicationAST(set[Declaration] decls){

	map[list[str],list[tuple[loc, int]]] blockHashes;
	map[list[str],list[tuple[loc location, int index]]] blockHashesFiltered;
	map[loc, list[int]] locIndexMap;
	map[loc, int] dupLoc;
	list[loc] allMethods;

	// get hashes of all strings with their locations
	<blockHashes, allMethods> = MapCodeOnDuplicationAST(decls);
	
	// filter non duplicated entries for duplication calculation
	blockHashesFiltered = (a:blockHashes[a] | a <- domain(blockHashes), size(blockHashes[a])>1);

	// get a map of indices of duplicated blocks for each loc
	locIndexMap = getLocIndex(blockHashesFiltered);	
	
	// sort indices in new map in asc order
	locIndexMap = sortIndex(locIndexMap);
	
	// get lines of duplicated code (per loc)
	dupLoc = getLocs(locIndexMap);

	 // return after completing the list with unanalyzed methods
	return addNullMethods(dupLoc, allMethods);

}

// Gets a map of strings combined with their occurences (as location and index in that location) and a list of visited locs
private tuple[map[list[str], list[tuple[loc, int]]], list[loc]] MapCodeOnDuplicationAST(set[Declaration] decls){

	map[list[str], list[tuple[loc, int]]] codeMap = ();
	map[loc, list[str]] strMap = ();
	list[loc] locationList = [];

	for(file <- decls){
		
		list[tuple[loc location, list[str] strings]] strTup = [];
		
		// visit file abstract syntax tree, create tuples of location and strings	
		visit(file){
			// we consider methods...
			case m: \method(_, _, _, _,Statement impl): {
				strTup += <m.src,getStrFromStatement(impl)>;
			}
			// ... and constructors
			case m: \constructor(_, _, _, Statement impl): {
				strTup += <m.src,getStrFromStatement(impl)>;
			}
		}
		
		//visit every element in the resulting tuple
		for(i <- strTup){
			//we are only interested in locations with more lines than the detection block limmit
			if(size(i.strings)-blockSize >= 0){
				//we check for each of these blocks if it is already in our codemap...
				for(j <- [0..(size(i.strings)-blockSize+1)]){
					fileLines = i.strings[j..j+blockSize];
					if(fileLines in codeMap)
						// ... and at the occurence if it is already there
						codeMap[fileLines]+=[<i.location, j>];
					else
						//... or we add an entirely new entry if it isn't there yet!
						codeMap[fileLines]=[<i.location,j>];							
				}
			}
			locationList += i.location;
		}	
	}
	
	return <codeMap, locationList>;	
}

// this function basically inverts a map of strings (as keys) with locations+indices (as values) in order to get a list of indices per location
private map [loc, list[int]] getLocIndex(map[list[str],list[tuple[loc location, int index]]] blockHashes){
	
	map [loc, list[int]] retVal = ();
	
	// cycle over full input map
	for(i<-domain(blockHashes)){
		// cycle over tuple list for element i and store in the retVal map	
		for(j <- blockHashes[i]){	
			if(j.location in retVal){
				retVal[j.location] += [j.index];
			}
			else{
				retVal[j.location] = [j.index];
			}
		}
	}
	return retVal;
}

// returns a list of strings from a statement (= method content in this case)
private list[str] getStrFromStatement(Statement s){
	return filteredFile = FilterSingleFile(s.src);
}

// this method returns a map of duplication for each location based on a map of indices of duplicated blocks for these locations
private map[loc, int] getLocs(map[loc, list[int]] mapIn){

	map[loc, int] retVal = ();

	int tmp = 0;
	int prev = 0;

	// loop over full map
	for(i <- domain(mapIn)){	
		// base value = block size
		tmp = blockSize;
		if(size(mapIn[i]) >= 2){
			// by setting the first "previous" value for comparisson to the first one in the list we basicallly ignore it as it has no overlap
			prev = mapIn[i][0]; 
			// loop over indices
			for(j <- mapIn[i]){
				tmp += quantifyOverlap(prev, j);
				prev = j;				
			}
		}
		retVal += (i:tmp);
	}
	
	return retVal;
}

//estimate based on two indices how many lines are overlapped (e.g. if i1 = 1 and i2 = 2 there are 2 unique lines (first of i1 and last of i2) and 5 overlapping lines, the total would be 7)
private int quantifyOverlap(int a, int b){
	delta = max(a,b) - min(a,b);
	overlap = blockSize - delta;

	if(overlap <= 0)
		return blockSize; 
	
	return blockSize - overlap;
}

// sorts indices in ascending order in order to find the overlapping parts in later phases
private map[loc, list[int]] sortIndex(map[loc, list[int]] mapIn){
	return (a:sort(mapIn[a]) | a <- domain(mapIn));	
}

// adds "small" methods and other missing functions to map. We give these methods the maximum rating, while this is not correct (they might be duplicated as well) they are not detectable because of our selected granularity, thus they should not be flagged as bad either.
private map[loc, int] addNullMethods(map[loc, int] mapIn, list[loc] allMethods){
	retVal = mapIn;
	for(i <- allMethods){
		if(!(i in mapIn))
			retVal += (i:0);
	}
	return retVal;
}