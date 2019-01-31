module View::TreeView

import vis::Figure;
import vis::Render;
import vis::treemap;
import vis::button;
import vis::vcat;
import vis::hcat;
import vis::KeySym;
import List;
import IO;
import Helpers::DataContainers;

import String;

//alias projectPart = lrel[int linesOfCode,sigRating rating,map[string, projectPart] content, bool render];
//alias sigRating = lrel[int size,int duplication,int complexity,int unitSize, int unitTest];

//alias AnalyzedObject = tuple[str objName, str objType];
//data TreeMap = treeMap(loc location, AnalyzedObject abj, SIGRating rating, map[loc,TreeMap] children,int cl, bool render);
//alias SIGRating = tuple[int uLoc, int uComp, int uDup, int uTest];

[] Navigationquee;

SigFilter SelectedFilter;
//alias SigFilter = lrel[bool Loc, bool Comp, bool Dupl, bool Test];

void main()
{

}

Figure FilterBoxes()
{
	Loc =  checkbox("Lines of Code",void(bool s){SelectedFilter.Loc = s;},shadow(true),fillColor("LightGray"));
    Comp =  checkbox("Complexity",void(bool s){SelectedFilter.Comp = s;},shadow(true),fillColor("LightGray"));
    Dupl =  checkbox("Duplication",void(bool s){SelectedFilter.Dupl = s;},shadow(true),fillColor("LightGray"));
    Test =  checkbox("Test",void(bool s){SelectedFilter.Test = s;},shadow(true),fillColor("LightGray"));

	return hcat([Loc,Comp,Dupl,Test],vshrink(0.1),gap(25));
}

Figure DetailText()
{
	return box(text("This are the details of my currently hoovered object"),vshrink(0.2));
}

Figure TitleText()
{
	return box(text("Current Title of subobject",fontSize(20)),vshrink(0.1));
}

void ShowGUI(BrowsableMap myData)
{
	/*AllData = myData;
	SelectedItem = myData;*/
	
	Navigationquee = [myData];
	
	render(
		vcat(
			[
			FilterBoxes(),
			DetailText(),			
			TitleText(),
			RenderTreeMap()
			], gap(10)
		)
	);
}

void RepaintGUI()
{
	render(
		vcat(
			[
			FilterBoxes(),
			DetailText(),			
			TitleText(),
			RenderTreeMap()
			], gap(10)
		)
	);
}

Figure RenderTreeMap()
{
	figureList = [];

	for(myMapKey <-  Navigationquee[size(Navigationquee)-1].children)
	{
		thisObj =  Navigationquee[size(Navigationquee)-1].children[myMapKey];
		//println("My Map Key: <myMapKey>");
		//println("MyMap Name: <thisObj.abj.objName> with children <thisObj.children>");		
		figureList+=box(text(thisObj.abj.objName),fillColor(GetRatingColor(thisObj.rating)),area(thisObj.globalVars.lineCount),
			onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			
			if(butnr==1)
			{
				Navigationquee += thisObj;
				RepaintGUI();
			}
	
			if(butnr==3)
			{
				Navigationquee = delete(Navigationquee,size(Navigationquee)-1);
				RepaintGUI();
			}
					
			return true;
			}));
	}

	return treemap(figureList,fillColor("red"),vshrink(0.6));
}


/*Figure RenderTreeMap(BrowsableMap myData, BrowsableMap parent)
{
	figureList = [];

	for(myMapKey <- myData.children)
	{
		thisObj = myData.children[myMapKey];
		//println("My Map Key: <myMapKey>");
		//println("MyMap Name: <thisObj.abj.objName> with children <thisObj.children>");		
		figureList+=box(text(thisObj.abj.objName),fillColor(GetRatingColor(thisObj.rating)),area(thisObj.globalVars.lineCount),
			onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			
			if(butnr==1)
				render(RenderTreeMap(thisObj,myData));		
			if(butnr==3)
				render(RenderTreeMap(parent,thisObj));
					
			return true;
			}));
	}

	return treemap(figureList,fillColor("red"));
}*/

str GetRatingColor(SIGRating rating)
{
	//int uLoc, int uComp, int uDup, int uTest
	totalRate = (rating.uLoc + rating.uComp + rating.uDup + rating.uTest)/4;

	if(totalRate < -2)
		return "red";
	
	if(totalRate < -1)
		return "orange";
		
	if(totalRate < 0)
		return "yellow";
		
	if(totalRate < 1)
		return "GreenYellow";
		
	if(totalRate < 2)
		return "Green";
}

/*void tree RenderMap(renderData)
{

	//paint the entire stack 
	if(renderData.render)
	{
		for(item <- renderData.content)
		{
			RenderMap(item);
		}
	}
	else
	{
		return;
	}
}*/



