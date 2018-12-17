module Metrics::UnitSizeAlt

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import String;
import util::Resources;
import lang::java::jdt::m3::Core;
import lang::java::m3::AST;
import analysis::statistics::Descriptive;
import util::Math;

import Helpers::HelperFunctions;


public void analyzeMethodSize()
{
	loc project = |project://smallsql|;	
	// prepare AST
	set[loc] files = javaBestanden(project);
	set[Declaration] decls = createAstsFromFiles(files, false);	
	countMethods(project);		
}

// based on sample from YouLearn (first few lines only)
public map[str, real] AnalyzeUnitSize(set[Declaration] decls)
{
	// prepare ast -> now done globally
	// get unit sizes
	map[loc, int] unitSizes = getUnitSizeMap(decls);
	// get a risk factor
	map [loc, int] risk = (a : getRisk(unitSizes[a]) | a <- domain(unitSizes));
	// get a count of all evaluated units
	int evaluatedUnits = getRangeSum(unitSizes);
	// then get one map per risk level with the unit size of each method
	map [loc, int] lowRisk = (a:unitSizes[a] | a <- domain(risk), risk[a] == 1);
	map [loc, int] moderateRisk = (a:unitSizes[a] | a <- domain(risk), risk[a] == 0);
	map [loc, int] highRisk = (a:unitSizes[a] | a <- domain(risk), risk[a] == -1);
	map [loc, int] extremeRisk = (a:unitSizes[a] | a <- domain(risk), risk[a] == -2);
	// after that, get the relative percentage of these risk categories
	real factionLow = toReal(getRangeSum(lowRisk))/evaluatedUnits;
	real factionModerate = toReal(getRangeSum(moderateRisk))/evaluatedUnits; 
	real factionHigh = toReal(getRangeSum(highRisk))/evaluatedUnits;
	real factionExtreme = toReal(getRangeSum(extremeRisk))/evaluatedUnits;

	return ("factionLow":factionLow,"factionModerate":factionModerate,"factionHigh":factionHigh,"factionExtreme":factionExtreme);
}

// this variation of the above method is used by other classes to get the unit size
public map[loc, int] countMethods(set[Declaration] ASTDeclarations)
{
	// get unit sizes
	map[loc, int] unitSizes = getUnitSizeMap(ASTDeclarations);
	int totalSize = getRangeSum(unitSizes); 

	return unitSizes;
}

// 
private map [loc, int] getUnitSizeMap(set[Declaration] decls)
{
	map[loc, int] unitSize = ();
	Declaration file;

	for(file <- decls){	
		visit(file) {  
			// methods are defined as either (tutor.rascal-mpl.org):
			// a: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl)
   			// b: \method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions)
   			// we only consider type a since type b all seem to be abstract methods that do not add lines of code to the executable methods
			case \method(_, _, _, _,Statement impl): {
				unitSize += getUnitSize(impl);
			}
			// we also consider the constructors as these may contain elements that affect the complexity
			case \constructor(_, _, _, Statement impl): {
				unitSize += getUnitSize(impl);
			}
		}
	}
	return unitSize;
}

private map [loc, int] getUnitSize(Statement s){
	return (s.src:size(FilterSingleFile(s.src)));
}

// gets the complexity rating of a method in the range [2; -1]
private int getRisk(int unitSize){
	if(unitSize < 15) {
		// low risk
		return 1;
	}
	else if(unitSize < 30){
		// moderate risk
		return 0;
	}
	else if(unitSize < 60){
		// high risk
		return -1;
	}
	else {
		// very high risk
		return -2;
	}
}