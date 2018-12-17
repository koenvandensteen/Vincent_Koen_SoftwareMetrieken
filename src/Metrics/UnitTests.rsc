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

// based on sample from YouLearn (first few lines only)
public tuple[real, real] AnalyzeUnitTest(set[Declaration] ASTDeclarations)
{
	// We do not want the complexity of the unit tests to be a factor in the test coverage, we need a separate complexity rating for just the main code
	set[Declaration] pureDeclarations = {};

	list[str] testedMethods = []; // list of methods in test classes that perform tests
	list[str] projectMethods = [];// list of all other methods outside of test classes
	int assertCount = 0; // amount of assert statements in test methods
	int tested = 0; // amount of tested methods
	int untested = 0; // amount of untested methods
	int complexity = 0; // complexity of code excluding unit tests
	tuple [real v1, real v2] result = <0.0, 0.0>; // result tuple, v1 is naive result using tested/untested method counts, v2 more accurate using asserts
	
	// fill lists
	for(d <- ASTDeclarations){
		// get test method calls and assert count
		if(isTestClass(d)){
			testedMethods += getTestCalls(d);
			assertCount += getAssertCount(d);
		}
		// get tested methods and their declarations in order to count the cyclic complexity of the filtered methods
		else{
			projectMethods += getMethodsFromFile(d);
			pureDeclarations += d;
		}
	}
		
	//count code coverage
	for(i <- projectMethods){
		if(i in testedMethods){
			tested += 1;
		}
		else{
			untested+=1;
		}
	}
	
	// get filtered cyclicComplexity
	complexity = getRangeSum(AnalyzeUnitComplexity(pureDeclarations));
	// first real = naive approach 1 (method calls vs all methods using name matching), second real = assertCount/Complexity
	result = <toReal(tested)/size(projectMethods),toReal(assertCount)/complexity>;
	
	return result;
	
}


private list[str] getMethodsFromFile(Declaration d){
	list[str] methods = [];
	
	visit(d) { 
		case \method(_, str name, _, _, _): {
			methods += name;
		}
		case \method(_, str name, _, _): {
			methods += name;
		}
	}
	return methods;
}

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

// sees if junit.framework is imported in a class
private bool isTestClass(Declaration d){
	Declaration file;

	visit(d) {  
		// if everything was tested with junit, the first case below should have been enough
		case \import(str name): {	
			if( /.*junit.framework.*/ := name){
				return true;
			}
		}
		case \class(str name, _, _, _): {
			if( /.*test.*/ := name || /.*Test.*/ := name){
				return true;
			}
		}
	}

	return false;		
}

private bool isTestName(str s){
	return /test.*/ := s;
}

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

