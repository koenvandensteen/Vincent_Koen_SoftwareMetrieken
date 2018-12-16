module Agregation::SIGRating


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
		case 0:
			return "--";
	}
}