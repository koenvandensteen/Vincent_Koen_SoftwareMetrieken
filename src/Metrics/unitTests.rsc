module Metrics::unitTests

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

public void analyzeTests()
{
	loc project = |project://smallsql|;	
	//get complexity when used as stand-alone
	set[loc] files = javaBestanden(project);
	set[Declaration] decls = createAstsFromFiles(files, false);
	int complexity = getRangeSum(getCyclicComplexity(decls));	
	evaluateTests(decls, complexity );		
}


// based on sample from YouLearn (first few lines only)
public int evaluateTests(set[Declaration] ASTDeclarations, int cyclicComplexity)
{
	// prepare AST <- done globally
	// get list of tests and their assert-count
	//map[loc, int] unitTests = getUnitTests(decls);
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
	println("Total project methods = <size(projectMethods)> (excluding test methods), tested project methods = <tested>, untested = <untested>, asserts = <assertCount>, complexity = <cyclicComplexity>.");
	
	// very naive aproach: project methods/counted methods
	int overalRisk_V1 = getRisk(toReal(tested)/size(projectMethods));
	// naive approach: assert statements vs cc
	int overalRisk_V2 = getRisk(toReal(assertCount)/cyclicComplexity);
	
	println("V1 risk: <overalRisk_V1>, V2 risk: <overalRisk_V2>");
	
	return overalRisk_V2;
	
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

// gets the complexity rating of a method in the range [2; -1]
public int getRisk(real coverage){
	if(coverage > 0.95) {
		// low risk
		return 2;
	}
	else if(coverage > 0.8){
		// moderate risk
		return 1;
	}
	else if(coverage > 0.6){
		// high risk
		return 0;
	}
	else if(coverage > 0.2){
		// high risk
		return -1;
	}
	else {
		// very high risk
		return -2;
	}
}


//public void evaluateTestsM3(loc project){
//	M3 model = createM3FromEclipseProject(project);
//	
//	// get all methods of the core project and all test methods 
//	testMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method", /.*Test.*/ := a.uri, /test.*()/:= getMethodFromPath(b.uri)};
//	coreMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method", a notin domain(testMethods)};	
//		
//	// prepare AST
//	set[loc] files = javaBestanden(project);
//	set[Declaration] decls = createAstsFromFiles(files, false);
//	
//	for(d <- decls){
//		visit(d){
//			case c:\class(str name, _, _, _): {
//				println(c);
//			}
//		}
//	}
//
//
//// debug
//	for(i <- range(testMethods)){
//		//if(/test.*()/:=i.uri)
//		//println(i);
//		//println(readFile(i));
//		int j = 0;
//	}
//	
//	
//
//}
//
//
//public list[loc] getCalledMethods(set[Declaration] dcls){
//	list[loc] called = [];
//	
//	for(d <- dcls){
//		visit(d){
//			case  a:\methodCall(_, str name, _): {	
//				println(d);
//				println();
//				println(a);
//				println();
//				println();
//			}
//			case  a:\methodCall(_, _, str name, _): {	
//				println(a);
//			}
//		}
//	}
//	
//	return called;
//}

//public str getMethodFromPath(str s){
//	int i = findLast(s, "/");
//	return substring(s, i + 1);
//}
