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
	map[loc, int] unitTests = getUnitTests(decls);
	// get a list of methods
	list[loc] methods = getProjectMethods(decls);
}

public list[loc] getProjectMethods(set[Declaration] d){
	list[loc] methods = [];
	Declaration file;

	for(file <- d){	
		visit(file) {  
			case \method(_, _, _, _,Statement impl): {
				//TODO
				methods = [];
			}
		}
	}
	return methods;
}


public map[loc, int] getUnitTests(set[Declaration] d){
	map [loc, int] tests = ();
	Declaration file;

	for(file <- d){	
		if (isTestClass(file)){
			assertCount = getAssertCount(file);
			println("assertCount <assertCount>");
			visit(file) { 
				//case \class(list[Declaration] body): {
				//	int i = 0;
				//}
				case \methodCall(_, Expression receiver, str name, _): {
					//println("receiver <receiver.name>");
					//println("Method call name <name>");
					int i = 1;
				}
			}
		}
	}
	println(tests);
	return tests;
}

// sees if junit.framework is imported in a class
public bool isTestClass(Declaration d){
	Declaration file;

	for(file <- d){	
		visit(file) {  
			case \import(str name): {	
				if( /.*junit.framework.*/ := name){
					return true;
				}
			}
		}
	}
	return false;		
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