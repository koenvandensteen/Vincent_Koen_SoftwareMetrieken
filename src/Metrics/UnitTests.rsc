module Metrics::UnitTests

import Set;
import Map;
import List;
import ListRelation;
import Relation;
import IO;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import String;
import util::Math;

import Helpers::HelperFunctions;
import Metrics::UnitComplexity;

// based on sample from YouLearn (first few lines only)
public tuple[real, real] AnalyzeUnitTest(set[Declaration] ASTDeclarations)
{
	// We do not want the complexity of the unit tests to be a factor in the test coverage, we need a separate complexity rating for just the main code
	set[Declaration] pureDeclarations = {};

	// prepare AST <- done globally
	// get list of tests and their assert-count
	// get a list of methods
	list[str] testedMethods = [];
	list[str] projectMethods = [];
	
	int assertCount = 0;
	// fill lists
	for(d <- ASTDeclarations){
		// get test method calls and assert count
		if(isTestClass(d)){
			testedMethods += getTestCalls(d);
			assertCount += getAssertCount(d);
		}
		// get tested methods
		else{
			projectMethods += getMethodsFromFile(d);
			pureDeclarations += d;
		}
	}
	
	// get filtered cyclicComplexity
	int complexity = getRangeSum(AnalyzeUnitComplexity(pureDeclarations));
	
	//count code coverage
	int tested = 0;
	int untested = 0;
	for(i <- projectMethods){
		if(i in testedMethods){
			tested += 1;
		}
		else{
			untested+=1;
		}
	}
	// debug prints
		
	// very naive aproach: project methods/counted methods
	//int overalRisk_V1 = getRisk(toReal(tested)/size(projectMethods));
	//println("Total project methods = <size(projectMethods)> (excluding test methods), tested project methods = <tested>, untested = <untested>, asserts = <assertCount>, complexity = <complexity>.");		
	// naive approach: assert statements vs cc
	//int overalRisk_V2 = getRisk(toReal(assertCount)/cyclicComplexity);
	// percentage coverage
	//println("V1 risk: <overalRisk_V1>, V2 risk: <overalRisk_V2>");
	
	// first real = naive approach 1 (method calls vs all methods using name matching), second real = assertCount/Complexity
	tuple [real v1, real v2] result = <toReal(tested)/size(projectMethods),toReal(assertCount)/complexity>;
	
	return result;
	
}


public list[str] getMethodsFromFile(Declaration d){
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

public list[str] getTestCalls(Declaration d){
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
public bool isTestClass(Declaration d){
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

public bool isTestName(str s){
	return /test.*/ := s;
}

public int getAssertCount(Declaration d){
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
			// does not seem to add anything
			//case \assert(Expression expression): {
			//	println("debug assert: <file>");
			//	println("a3 <expression>");
			//}
			//case \assert(Expression expression, _): {
			//	println("debug assert: <file>");
			//	println("a <expression>");
			//}
		}
	}
	return count;
}

