module Metrics::unitTests

import Set;
import Map;
import List;
import IO;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Helpers::HelperFunctions;

public void analyzeTests()
{
	loc project = |project://smallsql|;	
	evaluateTests(project);		
}

// based on sample from YouLearn (first few lines only)
public void evaluateTests(loc project)
{
	// prepare AST
	set[loc] files = javaBestanden(project);
	set[Declaration] decls = createAstsFromFiles(files, false);
	// get list of tests and their assert-count
	//map[loc, int] unitTests = getUnitTests(decls);
	// get a list of methods
	list[str] testedMethods = [];
	list[str] projectMethods = [];
	
	int assertCount = 0;
	// fill lists
	for(d <- decls){
		// get test method calls and assert count
		if(isTestClass(d)){
			testedMethods += getTestCalls(d);
			assertCount += getAssertCount(d);
		}
		// get tested methods
		else{
			projectMethods += getMethodsFromFile(d);
		}
	}
	
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
	println("Tested = <tested>, untested = <untested>, asserts = <assertCount>.");
	

}

//getRangeSum


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
				if(!(/assert.*/ := c)){
					testCalls += c;
				}				
			}
			
			case \methodCall(_, str c, _): {
				if(!(/assert.*/ := c)){
					testCalls += c;
				}
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
			case \assert(Expression expression): {
				println("debug assert: <file>");
				println("a3 <expression>");
			}
			case \assert(Expression expression, _): {
				println("debug assert: <file>");
				println("a <expression>");
			}
		}
	}
	return count;
}