module Helpers::DataContainers

//aliases
alias projectList = lrel[loc location,list[str] stringList];
alias maintainAbilityRating = tuple[int analysability,int changeability, int stability, int testability];
alias AnalyzedObject = tuple[str objName, str objType];
alias SIGRating = tuple[int uLoc, int uComp, int uDup, int uTest];
alias GlobalVars =  tuple[real dupPercent, real testPercent, int lineCount];
alias Workset = map[loc wLocation, tuple[SIGRating wRating, GlobalVars wGlobal] wData];
alias ProgramConfigs = tuple[bool colorBlind, bool noTest, bool aboutBox, bool showDetails, str currentProject, str currentMetric];

//datatypes
data BrowsableMap = browsableMap(loc location, AnalyzedObject abj, SIGRating rating, GlobalVars globalVars, map[tuple[loc, str], BrowsableMap] children);