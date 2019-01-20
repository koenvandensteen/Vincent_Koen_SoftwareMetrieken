module Metrics::UnitTests

import Set;
import List;
import IO;
import util::Resources;
import lang::java::m3::AST;
import util::Math;
import ListRelation;
import Relation;
import String;
import lang::java::jdt::m3::Core;
import Map;

import Helpers::HelperFunctions;
import Metrics::UnitComplexity;

//returns two variables that describe the test coverage
public tuple[real, real] processUnitTestMap(map [loc, int] tstCount, set[Declaration] ASTDeclarations){

	list[str] testedMethods = []; // list of methods in test classes that perform tests
	int complexity = 0; // complexity of code excluding unit tests
	map[loc, int] tstCountFilt = ();// locs paired with a value 0 if untested or 1 if tested
	tuple [real v1, real v2] result = <0.0, 0.0>; // result tuple, v1 is naive result using tested/untested method counts, v2 more accurate using asserts
	
	tuple[set[Declaration] pureDeclarations, map[loc, str] projectMethods, int assertCount, list[str] tM, map[loc, str] tM2] helper = duplicateHelper(ASTDeclarations);

	// tstCount returns test classes with "-1" as value, we do not wish to count these so filter those out
	tstCountFilt = (a:tstCount[a] | a <- domain(tstCount), tstCount[a] > -1); 
	// get filtered cyclicComplexity
	complexity = getRangeSum(AnalyzeUnitComplexity(helper.pureDeclarations));
	// first real = naive approach 1 (method calls vs all methods using name matching), second real = assertCount/Complexity
	result = <toReal(getRangeSum(tstCountFilt))/size(helper.projectMethods),toReal(helper.assertCount)/complexity>;

	return result;

}

// returns a map with locations and a 1 (if the method has a matching call in a test file) or a zero (otherwise)
public map[loc, int] AnalyzeUnitTestMap(set[Declaration] ASTDeclarations){

	tuple[set[Declaration] pD, map[loc, str] projectMethods, int aC, list[str] testedMethods, map[loc, str] testMethods] helper = duplicateHelper(ASTDeclarations);

	map [loc, int] tstCount = ();

	//count code coverage
	for(i <- domain(helper.projectMethods)){	
		if(helper.projectMethods[i] in helper.testedMethods){
			tstCount[i] = 1;
		}
		else{
			tstCount[i] = 0;
		}
	}
	
	// add test methods with count "-1" as flag
	for(i <- domain(helper.testMethods)){
		tstCount[i] = -1;
	}
	
	return tstCount;
}

// this helper method is created because the unit test module is approached in two distinct but intertwined ways. 
// using the helper enables us to reuse code. The method itself generates four variables that are only used as intermediate results.
private tuple[set[Declaration] pureDeclarations, map[loc, str] projectMethods, int assertCount, list[str] testedMethods, map[loc, str] testMethods] duplicateHelper(set[Declaration] ASTDeclarations){

	set[Declaration] pureDeclarations = {}; // We do not want the complexity of the unit tests to be a factor in the test coverage, we need a separate complexity rating for just the main code
	map[loc, str] projectMethods = ();
	map[loc, str] testMethods = ();
	int assertCount = 0; // amount of assert statements in test methods
	list[str] testedMethods = [];	

	// fill lists
	for(d <- ASTDeclarations){
		// get test method calls and assert count
		if(isTestClass(d)){
			testMethods += getMethodsFromFile(d);
			testedMethods += getTestCalls(d);
			assertCount += getAssertCount(d);
		}
		// get tested methods and their declarations in order to count the cyclic complexity of the filtered methods
		else{
			projectMethods += getMethodsFromFile(d);
			pureDeclarations += d;
		}
	}
	
	return <pureDeclarations, projectMethods, assertCount, testedMethods, testMethods>;
}

/*
private map[str, loc] getMethodLocs(Declaration d){

	map[str, loc] retVal = ();

	visit(d) {  
		// methods are defined as either (tutor.rascal-mpl.org):
		// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
		// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
		// we only consider type a since type b all seem to be abstract methods that do not add complexity
		case m: \method(_, str name, _, _, _): {
			retVal += (name:m.src);
		}
		// we also consider the constructors as these may contain elements that affect the complexity
		case m: \constructor(str name, _, _, _): {
			retVal += (name:m.src);
			println(m.src);
		}
		case m: \constructor(_, _, _, _): {
			locNameList += (m.src:m.name);
			println(m.src);
			println(m.name);
		}
	}

	return retVal;

}
*/

// returns a map of locations and the name for all methods in a declaration
private map[loc, str] getMethodsFromFile(Declaration d){
	map[loc, str] methods = ();
	
	visit(d) { 
		case m:\method(_, str name, _, _, _): {
			methods += (m.src:name);
		}
		case m:\method(_, str name, _, _): {
			methods += (m.src:name);
		}
		case m: \constructor(str name, _, _, _): {
			methods += (m.src:name);
		}
	}
	return methods;
}

// returns all method calls found in a declaration
private list[str] getTestCalls(Declaration d){
	list[str] testCalls = [];
	list[Statement] statList = [];
	Statement s;	
	
	visit(d) {
		case a:\method(_, str name, _, _, Statement impl) :{
			if(isTestName(name)){
				statList += impl;
			}
		}
	}

	for(s <- statList){	
		visit(s) { 
			case \methodCall(_, _, str c, _): {
				//if(!(/assert.*/ := c)){
					testCalls += c;
				//}				
			}
			
			case \methodCall(_, str c, _): {
				//if(!(/assert.*/ := c)){
					testCalls += c;
				//}
			}

		}
	}
	return testCalls;
}

// sees if a string indicates a test class/method
private bool isTestName(str s){
	return /test.*/ := s;
}

// counts assert statements in a declaration
private int getAssertCount(Declaration d){
	Declaration file;
	int count = 0;

	for(file <- d){	
		visit(file) {  
			case  \methodCall(_, str name, _): {	
				if(/assert.*/ := name){
					count += 1;
				}
			}
			case  \methodCall(_, _, str name, _): {	
				if(/assert.*/ := name){
					count += 1;
				}
			}
		}
	}
	return count;
}

