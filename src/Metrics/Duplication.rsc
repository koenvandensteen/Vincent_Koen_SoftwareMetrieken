module Metrics::Duplication

import IO;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import List;
import Map;
import Relation;
import Set;
import String;

import Helpers::HelperFunctions;
import ListRelation;
import Helpers::DataContainers;


int blockSize = 6;

public map[loc, int] AnalyzeDuplicationAST(set[Declaration] decls){

	map[list[str],list[tuple[loc location,int index]]] blockHashes = MapCodeOnDuplicationAST(decls);
	
	map[loc,list[int]] duplicationIndexList = ();
	
	int countDuplicateblocks = 0;
	
	for(codeMapKeys <- blockHashes)
	{
		//the block hash of the map has more then one occurance, so it is duplicated at least once.
		if(size(blockHashes[codeMapKeys])>1)
		{
			/*
			//this location has been added previously, we now have to check if it is a complete new block or
			//an addional line
			*/
			if(blockHashes[codeMapKeys][0].location in duplicationIndexList)
			{
				if(IsIndexPresent(duplicationIndexList[blockHashes[codeMapKeys][0].location],blockHashes[codeMapKeys][0].index))
				{
					//our index was already present so altough this is a new block, its only counted as one addional line because
					//we count one line at a time.
					countDuplicateblocks+= size(blockHashes[codeMapKeys])-1;
					/*println("already exisiting block +<size(blockHashes[codeMapKeys])-1> line");
					println("found in <blockHashes[codeMapKeys][0].location> line");
					println("code block found: <codeMapKeys>");*/
				}
				else
				{
					//this is a completely new block, so we add the block size completely.
					countDuplicateblocks+= (size(blockHashes[codeMapKeys])-1)*blockSize;
					/*println("new block in existing code location +<(size(blockHashes[codeMapKeys])-1)*blockSize> line");
					println("found in <blockHashes[codeMapKeys][0].location> line");
					println("code block found: <codeMapKeys>");*/
				}
				duplicationIndexList[blockHashes[codeMapKeys][0].location]+=[blockHashes[codeMapKeys][0].index];
			}
			/*
			//this location wasn't counted in at all, so we count the ammount of times the block appeared
			//and multiply it times the size of our block size.
			*/
			else
			{
				duplicationIndexList[blockHashes[codeMapKeys][0].location]=[blockHashes[codeMapKeys][0].index];
				countDuplicateblocks+= (size(blockHashes[codeMapKeys])-1)*blockSize;
				/*println("new block in non exisiting code location +<(size(blockHashes[codeMapKeys])-1)*blockSize> line");
				println("found in <blockHashes[codeMapKeys][0].location> line");
				println("code block found: <codeMapKeys>");*/
			}			
		}
	}
	
	println("dup blocks: <countDuplicateblocks>");
	
	map [loc, int] temp = ();
	return temp;


}

public map[list[str],list[tuple[loc location,int index]]] MapCodeOnDuplicationAST(set[Declaration] decls)
{

	codeMap = ();
	map[loc, list[str]] strMap = ();
	
	//int i = 0;
	
	for(file <- decls){
	
		strLst = [];
		
		println(file);
		println("________");
		
		visit(file){
			//
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add lines of code to the executable methods
			case \method(_, _, _, _,Statement impl): {
				strLst += (getStrFromStatement(impl));
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case m: \constructor(_, _, _, Statement impl): {
				strLst += (getStrFromStatement(impl));
			}
			//
			
		}
		
		// for-loop from original version
		if((size(strLst)-blockSize) > 0)
		{
			for(i <- [0..(size(strLst)-blockSize)])
			{
				fileLines = strLst[i..i+blockSize];
				if(fileLines in codeMap)
					codeMap[fileLines]+=[<file.src,i>];
				else
					codeMap[fileLines]=[<file.src,i>];
			}
		}
	}

	println(size(codeMap));
	//for(i < [0.. size(codeMap)]){
		println(codeMap);
	//}
	return codeMap;	
}

private list[str] getStrFromStatement(Statement s){
	return filteredFile = FilterSingleFile(s.src);
}

	
public int AnalyzeDuplication(projectList)
{	
	map[list[str],list[tuple[loc location,int index]]] blockHashes = MapCodeOnDuplication(projectList);
	
	map[loc,list[int]] duplicationIndexList = ();
	
	int countDuplicateblocks = 0;
	
	for(codeMapKeys <- blockHashes)
	{
		//the block hash of the map has more then one occurance, so it is duplicated at least once.
		if(size(blockHashes[codeMapKeys])>1)
		{
			/*
			//this location has been added previously, we now have to check if it is a complete new block or
			//an addional line
			*/
			if(blockHashes[codeMapKeys][0].location in duplicationIndexList)
			{
				if(IsIndexPresent(duplicationIndexList[blockHashes[codeMapKeys][0].location],blockHashes[codeMapKeys][0].index))
				{
					//our index was already present so altough this is a new block, its only counted as one addional line because
					//we count one line at a time.
					countDuplicateblocks+= size(blockHashes[codeMapKeys])-1;
					/*println("already exisiting block +<size(blockHashes[codeMapKeys])-1> line");
					println("found in <blockHashes[codeMapKeys][0].location> line");
					println("code block found: <codeMapKeys>");*/
				}
				else
				{
					//this is a completely new block, so we add the block size completely.
					countDuplicateblocks+= (size(blockHashes[codeMapKeys])-1)*blockSize;
					/*println("new block in existing code location +<(size(blockHashes[codeMapKeys])-1)*blockSize> line");
					println("found in <blockHashes[codeMapKeys][0].location> line");
					println("code block found: <codeMapKeys>");*/
				}
				duplicationIndexList[blockHashes[codeMapKeys][0].location]+=[blockHashes[codeMapKeys][0].index];
			}
			/*
			//this location wasn't counted in at all, so we count the ammount of times the block appeared
			//and multiply it times the size of our block size.
			*/
			else
			{
				duplicationIndexList[blockHashes[codeMapKeys][0].location]=[blockHashes[codeMapKeys][0].index];
				countDuplicateblocks+= (size(blockHashes[codeMapKeys])-1)*blockSize;
				/*println("new block in non exisiting code location +<(size(blockHashes[codeMapKeys])-1)*blockSize> line");
				println("found in <blockHashes[codeMapKeys][0].location> line");
				println("code block found: <codeMapKeys>");*/
			}			
		}
	}
	
	return countDuplicateblocks;
}

//We check here if our current index already is present within a previous added block index
private bool IsIndexPresent(list[int] indexList,int index)
{
	for(i <- indexList)
	{
		if(index > i && index <= i + blockSize)
			return true;
	}
	return false;
}

//This fucntion basically splits the code up into blocks of a determined block size, SIG suggests to take 6 as a duplicate 
//treshhold we then place these values into a map which transform the list into a hashvalue
//if we have a new ocuring we place a new entry in the map, else we add the location to our previous position.
public map[list[str],list[tuple[loc location,int index]]] MapCodeOnDuplication(projectList)
{

	blockList = [];
	codeMap = ();

	for(file <- projectList)
	{				
		for(i <- [0..(size(file.stringList)-blockSize)])
		{
			fileLines = file.stringList[i..i+blockSize];
			if(fileLines in codeMap)
				codeMap[fileLines]+=[<file.location,i>];
			else
				codeMap[fileLines]=[<file.location,i>];
		}
	}	
	
	return codeMap;	
}





