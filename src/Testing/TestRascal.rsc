module Testing::TestRascal


//general imports
import IO;
import lang::java::m3::AST;
import Set;
import Map;
//helper files
import Helpers::HelperFunctions;
import Helpers::DataContainers;
//modules to be tested
import Metrics::UnitSizeAlt;
import Metrics::UnitComplexity;
import Metrics::LOC;
import Metrics::Duplication;

public void TestAll(){
	// initialise 
	loc project = |project://SimpleJavaDemo|;	
	// prepare AST
	set[loc] files = getFilesJava(project);
	set[Declaration] ASTDeclarations = createAstsFromFiles(files, false);	
	// pre-filter project
	projectList filteredProject = FilterAllFiles(files);	
	
	//run tests
	TestAnalyzeUnitSize(ASTDeclarations);
	TestAnalyzeUnitComplexity(ASTDeclarations);
	TestLOC(filteredProject);
	TestDuplication(filteredProject);
}

// unit size test
public void TestAnalyzeUnitSize(set[Declaration] ASTDeclarations){
	// for testing
	println("\nNow testing unit size:");
	map [loc, int] sizes = AnalyzeUnitSize(ASTDeclarations);	
	for(i <- domain(sizes)){
		println("<i> has <sizes[i]> lines.");
	}	
}

// unit complexity test
public void TestAnalyzeUnitComplexity(set[Declaration] ASTDeclarations){
	// for testing
	println("\nNow testing unit complexity:");
	map [loc, int] compl = AnalyzeUnitComplexity(ASTDeclarations);	
	for(i <- domain(compl)){
		println("<i> has complexity <compl[i]>.");
	}	
}

// LOC test
public void TestLOC(projectList filteredProject){
	// for testing
	println("\nNow testing total LOC:");	
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	println("total lines (filtered): <filteredLineCount>\n");
}

// duplicate test
public void TestDuplication(projectList filteredProject){
	// for testing
	println("\nNow testing duplication:");
	int duplicatedLines = AnalyzeDuplication(filteredProject);
	println("total lines duplicated: <duplicatedLines>\n");
}

// test sig ratings
public void sigRat(){
	// LOC
	int volumeRating = GetSigRatingLOC(filteredLineCount);
	totalReport+="**** line count SIG-rating: <transFormSIG(volumeRating)>\n";
	println(totalReport[size(totalReport)-1]);	
	// Duplication
	int duplicationRating = GetDuplicationRating(duplicatePercentage);
	totalReport+="**** duplication SIG-rating: <transFormSIG(duplicationRating)>\n";
	println(totalReport[size(totalReport)-1]);

}