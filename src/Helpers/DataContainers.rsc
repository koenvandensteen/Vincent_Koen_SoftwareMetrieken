module Helpers::DataContainers


alias projectList = lrel[loc location,list[str] stringList];
alias maintainAbilityRating = tuple[int analysability,int changeability, int stability, int testability];

//alias SigRating = tuple[int uLoc, int uCompl, int uDupl, int uTest];
//alias Content = tuple[SigRating sig, map[loc, Content] subContent];