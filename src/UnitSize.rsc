module UnitSize

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
	
	CountMethods(fileName);

	
}


public void CountMethods(loc fileName)
{
	
	
	
	M3 model = createM3FromEclipseProject(fileName);
	
	javaMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method"};
	
	methodCount = 0;
	lineCount = 0;
	maxLines = 0;
	maxLineMethod = "";
	
	// loop over all classes
	for(i <- domain(javaMethods)){
		// loop over all methods of class i
		methodCount = methodCount + 1;
		for(j <- javaMethods[i]){
			lines = size(readFileLines(j));
			lineCount = lineCount + lines;
			println("Methode <j> uit klasse <i> heeft <lines> regels code");
			//determine largest method
			if(lines > maxLines){
				maxLines = lines;
				maxLineMethod = j;
			}
		}
	}
	
	println("Er zijn <methodCount> methoden met in totaal <lineCount> regels code. Oftewel, het gemiddelde is <lineCount/methodCount> regels per methode");
	//println("Er zijn XXX getters en setters?");
	println("De grootste methode is <maxLineMethod> met <maxLines> regels code");
	
	println("");
	println("Volgende stappen: ");
	println("1 - goede methode om een uitgemiddeld resultaat uit te zoeken, e.g. getters en setters van 1 regel code hebben te grote impact. Statistisch, mediaan,...?");
	println("2 - classificeren (zie hulpmethode onderaan)");
	println("3 - negeren commentaren en witregels");
	
	//code below counts methods per class
//		M3 model = createM3FromEclipseProject(fileName);
		
//		javaMethods = {<a, b> | <a, b> <- model.containment, a.scheme=="java+class", b.scheme == "java+method"};
//		countMethods = {<a, size(javaMethods[a])> | a <- domain(javaMethods) };
//		averageLines = 0;
//		classCount = 0;
//		for(<_, n> <- countMethods){for(<c, m> <- sort(countMethods, sortHelper)){
//			classCount = methodCount + 1;	println("Class <c> has a count of <m> method(s)");
//			averageLines = averageLines + n;	};	
//			println("Claas <classCount> has <n> methods");	
//		}
//		println("The average count is <averageLines/methodCount>.");	
}


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