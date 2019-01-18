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

public void dupDebug(){
	println("******* START debug using smallsql *********");
	loc locProject = |project://smallsql|;
	
	//get AST
	M3 m3Project = createM3FromEclipseProject(locProject);
	set[loc] javaFiles = getFilesJava(locProject);
	set[Declaration] ASTDeclarations = createAstsFromFiles(javaFiles, false); 

	map[loc, int]  results = AnalyzeDuplicationAST(ASTDeclarations);
	
	println(getRangeSum(results));
}


// call this function to get the result as a single integer
public int AnalyzeDuplicationAST_int(set[Declaration] decls){
	return getRangeSum(AnalyzeDuplicationAST(decls));
}

//public map[loc, int] countDupsPerLoc(set[Declaration] decls){
public map[loc, int]  AnalyzeDuplicationAST(set[Declaration] decls){

	map[list[str],list[tuple[loc, int]]] blockHashes;
	map[list[str],list[tuple[loc location, int index]]] blockHashesFiltered;
	map[loc, list[int]] locIndexMap;
	map[loc, int] dupLoc;

	// get hashes of all strings with their locations
	blockHashes = MapCodeOnDuplicationAST(decls);

	// filter non duplicated entries
	blockHashesFiltered = (a:blockHashes[a] | a <- domain(blockHashes), size(blockHashes[a])>1);

	// get a map of indices of duplicated blocks for each loc
	locIndexMap = getLocIndex(blockHashesFiltered);
	
	// sort indices in new map in asc order
	locIndexMap = sortIndex(locIndexMap);
	
	// return lines of code (per loc)
	return getLocs(locIndexMap);

}

public map[loc, int] getLocs(map[loc, list[int]] mapIn){

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
public int quantifyOverlap(int a, int b){
	i = max(a,b);
	j = min(a,b);
	
	delta = i - j;
	overlap = blockSize - delta;

	if(overlap <= 0)
		return blockSize; //2* blocksize if calculating for only these 2!
	
	return blockSize - overlap; //(overlap+2*delta);
}

public map[loc, list[int]] sortIndex(map[loc, list[int]] mapIn){
	return (a:sort(mapIn[a]) | a <- domain(mapIn));	
}


public map [loc, list[int]] getLocIndex(map[list[str],list[tuple[loc location, int index]]] blockHashes){
	
	map [loc, list[int]] retVal = ();
	
	// cycle over full input map
	for(i<-domain(blockHashes)){
		// cycle over tuple list for element i
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

public map[list[str], list[tuple[loc, int]]] MapCodeOnDuplicationAST(set[Declaration] decls){

	map[list[str], list[tuple[loc, int]]] codeMap = ();
	map[loc, list[str]] strMap = ();
	
	for(file <- decls){
	
		strLst = [];	
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
				for(j <- [0..(size(i.strings)-blockSize)]){
					fileLines = i.strings[j..j+blockSize];
					if(fileLines in codeMap)
						// ... and at the occurence if it is already there
						codeMap[fileLines]+=[<i.location, j>];
					else
						//... or we add an entirely new entry if it isn't there yet!
						codeMap[fileLines]=[<i.location,j>];
				}
			}
		}	
	}
	
	return codeMap;	
}

private list[str] getStrFromStatement(Statement s){
	return filteredFile = FilterSingleFile(s.src);
}
