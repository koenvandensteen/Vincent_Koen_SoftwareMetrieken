module UnitComplexity

import IO;
import util::Resources;

import List;
import Map;
import Relation;
import Set;
import util::Resources;
import lang::java::jdt::m3::Core;

public void AnalyzeMethods()
{
	loc fileName = |project://smallsql|;
	
	evaluateMethods(fileName);

	println("todo general: classificatie van metrieken (zie Koen)");
	
}


public void evaluateMethods(loc fileName)
{
	
	M3 model = createM3FromEclipseProject(fileName);
	
	javaMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method"};
	

	
	// loop over all classes
	for(i <- domain(javaMethods)){
		// loop over all methods of class i
		for(j <- javaMethods[i]){
			AST = getMethdoASTEclipse(fileName, model);
			println(getMethodASTEclipse(fileName, model));
			//print(getCyclicComplexity(j, model));
		}
	}
	

}


public int getCyclicComplexity(loc fileName, M3 model)
{
//	ast = getAST(fileName, model);
//	int complexity = 0;
//	// base complexity for a method = 1
//	complexity += 1;
//	visit(ast){
//		case \if(_,_) : {
//			complexity += 1;
//			}
//		case \for(_,_) : {
//			complexity += 1;
//			}
//		case \while(_,_) : {
//			complexity += 1;
//			}
//		case \do(_,_) : {
//			complexity += 1;
//			}
//		case \foreach(_,_) : {
//			complexity += 1;
//			}
//		case \case(_,_) : {
//			complexity += 1;
//			}
//		}
	return -1;
}

//public Declaration getAST(loc fileName, M3 model){
//	return getMethodASTEclipse(fileName, model);
//}

public int GetComplexityRating(int totalLinesOfCode)
{
	if(totalLinesOfCode < 66000)
		return 2;
	else if(totalLinesOfCode < 246000)
		return 1;
	else if(totalLinesOfCode < 665000)
		return 0;
	else if(totalLinesOfCode < 1310000)
		return -1;
	else
		return -2;
}