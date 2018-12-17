module Agregation::SIGRating

import Helpers::DataContainers;
import util::Math;

public int GetSigRatingLOC(int LOC)
{
	if(LOC < 66000)
		return 2;
	else if(LOC < 246000)
		return 1;
	else if(LOC < 665000)
		return 0;
	else if(LOC < 1310000)
		return -1;
	else
		return -2;
}

public int GetDuplicationRating(num duplicationPercentage)
{
	if(duplicationPercentage < 3)
		return 2;
	else if(duplicationPercentage < 5)
		return 1;
	else if(duplicationPercentage < 10)
		return 0;
	else if(duplicationPercentage < 20)
		return -1;
	else
		return -2;
}

// gets the overal rating of the program in the range [2; -2]
public int GetUnitComplexityRating(real mid, real high, real extreme){
	if (mid <= 0.25 && high == 0 && extreme == 0){
		return 2;
	}
	if (mid <= 0.3 && high <= 0.05 && extreme == 0){
		return 1;
	}
	if (mid <= 0.4 && high <= 0.1 && extreme == 0){
		return 0;
	}
	if (mid <= 0.5 && high <= 0.15 && extreme <= 0.05){
		return -1;
	}
	else{
		return -2;
	}
}

// gets the complexity rating of a method in the range [1; -2]
public int GetUnitComplexityRisk(int complexity){
	if(complexity < 11) {
		// low risk
		return 1;
	}
	else if(complexity < 21){
		// moderate risk
		return 0;
	}
	else if(complexity < 51){
		// high risk
		return -1;
	}
	else {
		// very high risk
		return -2;
	}
}

// gets the overal rating of the program in the range [2; -2]
public int GetUnitSizeRating(real mid, real high, real extreme){
	if(mid <= 0.40 && high < 0.1 && extreme < 0.01)
		return 2;
	if (mid <= 0.42 && high < 0.191 && extreme < 0.056){ //4* rating based on Tubit EVulation
		return 1;
	}
	if (mid <= 0.5 && high <= 0.25 && extreme == 0.1){
		return 0;
	}
	if (mid <= 0.6 && high <= 0.30 && extreme == 0.15){
		return -1;
	}
	else{
		return -2;
	}
}

// gets the size rating of a method in the range [2; -1]
public int GetUnitSizeRisk(int unitSize){
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


public maintainAbilityRating GetMaintabilityRating(int volumeRating, int unitComplexityRating, int duplicationRating, int unitSizeRating, int unitTestingRating)
{
    int analysability = round((volumeRating + duplicationRating + unitSizeRating + unitTestingRating)/4.0);
    int changeability = round((unitComplexityRating + duplicationRating)/2.0);
    int stability = unitTestingRating;
    int testability = round((unitComplexityRating+unitSizeRating+unitTestingRating)/2.0);
    return <analysability,changeability,stability,testability>;
}

public int GetTotalSIGRating(maintainAbilityRating r)
{
	return round((r.analysability + r.changeability + r.stability + r.testability)/4.0);
}

public str transFormSIG(int ratingNumber)
{
	switch(ratingNumber)
	{
		case 2:
			return "++";
		case 1:
			return "+";
		case 0:
			return "0";
		case -1:
			return "-";
		case -2:
			return "--";
	}
}

