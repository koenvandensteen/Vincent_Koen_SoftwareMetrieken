module Helpers::DataContainers


alias projectList = lrel[loc location,list[str] stringList];
alias maintainAbilityRating = tuple[int analysability,int changeability, int stability, int testability];

//alias SigRating = tuple[int uLoc, int uCompl, int uDupl, int uTest];
//alias Content = tuple[SigRating sig, map[loc, Content] subContent];

alias AnalyzedObject = tuple[str objName, str objType];
alias SIGRating = tuple[int uLoc, int uComp, int uDup, int uTest];
//alias Workset = tuple[map[loc, str] tree, int lines, map[loc, int] uLoc, map[loc, int] uComp, map[loc, int] uDup, map[loc, int] uTest];

alias OveralResults = list[int];
alias Workset = map[loc wLocation, SIGRating wRating];
//alias TreeMap = tuple[loc location, AnalyzedObject aObj, list[TreeMap] rating];
data TreeMap = treeMap(loc location, AnalyzedObject abj, SIGRating rating, list[TreeMap] children);