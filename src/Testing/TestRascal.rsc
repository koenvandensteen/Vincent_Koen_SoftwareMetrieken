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
import Metrics::UnitSize;
import Metrics::UnitComplexity;
import Metrics::LOC;
import Metrics::Duplication;
import Metrics::UnitTests;

public void TestAll(){
	// expected results
	int vUnitSize = 85;
	int vComplexity = 24;
	int vLOC = 92;
	int vDuplicate = -1;
	tuple[real v1, real v2] vUnitTest = <1.0/5.0, 2.0/23.0>;

	// initialise 
	loc project = |project://SimpleJavaDemo|;	
	// prepare AST
	set[loc] files = getFilesJava(project);
	set[Declaration] ASTDeclarations = createAstsFromFiles(files, false);	
	// pre-filter project
	projectList filteredProject = FilterAllFiles(files);	
	
	//run tests
	s1 = TestAnalyzeUnitSize(ASTDeclarations, vUnitSize);
	s2 = TestAnalyzeUnitComplexity(ASTDeclarations, vComplexity);
	s3 = TestLOC(filteredProject, vLOC);
	s4 = TestDuplication(filteredProject, vDuplicate);
	s5 = TestAnalyzeUnitTests(ASTDeclarations, vUnitTest);
	
	println("\n All tests <(s1 && s2 && s3 && s4 && s5) ? "did":"did NOT"> succeed.");
}

// unit size test
public bool TestAnalyzeUnitSize(set[Declaration] ASTDeclarations, int verif){
	// for testing
	println("\nNow testing unit size:");
	int count = 0;
	map [loc, int] sizes = AnalyzeUnitSize(ASTDeclarations);	
	for(i <- domain(sizes)){
		println("<i> has <sizes[i]> lines.");
		count += sizes[i];
	}
	success = (verif := count);
	print("Are these results what we expect? - ");
	println(success ? "Yes" : "No");
	return success;
}

// unit complexity test
public bool TestAnalyzeUnitComplexity(set[Declaration] ASTDeclarations, int verif){
	// for testing
	println("\nNow testing unit complexity:");
	int count = 0;
	map [loc, int] compl = AnalyzeUnitComplexity(ASTDeclarations);	
	for(i <- domain(compl)){
		println("<i> has complexity <compl[i]>.");
		count += compl[i];
	}	
	success = (verif := count);
	print("Are these results what we expect? - ");
	println(success ? "Yes" : "No");
	return success;
}

// LOC test
public bool TestLOC(projectList filteredProject, int verif){
	// for testing
	println("\nNow testing total LOC:");	
	int filteredLineCount = GetTotalFilteredLOC(filteredProject);
	println("total lines (filtered): <filteredLineCount>");
	success = (verif := filteredLineCount);
	print("Are these results what we expect? - ");
	println(success ? "Yes" : "No");
	return success;
}

// duplicate test
public bool TestDuplication(projectList filteredProject, int verif){
	// for testing
	println("\nNow testing duplication:");
	int duplicatedLines = AnalyzeDuplication(filteredProject);
	println("total lines duplicated: <duplicatedLines>");
	
	success = (verif := duplicatedLines);
	print("Are these results what we expect? - ");
	println(success ? "Yes" : "No");
	return success;
}

public bool TestAnalyzeUnitTests(set[Declaration] ASTDeclarations, tuple [real v1, real v2] verif){	
	// for testing
	println("\nNow testing test coverage:");
	tuple[real v1, real v2] unitTest = AnalyzeUnitTest(ASTDeclarations);
	println("Test coverage based on method pairing: <unitTest.v1>");
	println("Test coverage based on assert count: <unitTest.v2>");
	
	success = ((verif.v1 == unitTest.v1) && (verif.v2 == unitTest.v2));
	print("Are these results what we expect? - ");
	println(success ? "Yes" : "No");
	return success;
	
}


// under here not finished!

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