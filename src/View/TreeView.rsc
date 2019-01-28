module View::TreeView

import vis::Figure;
import vis::Render;
import vis::treemap;
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

void main()
{
	
	figures = [];
	
	
	intList = [10,5,10,15,20,15];
	
	for(int number <- intList)
	{
		figures += box(text("jada"),area(number),fillColor("grey"));
		figures += box(text("jada"),area(number),fillColor("red"));
		figures += box(text("jada"),area(number),fillColor("blue"));
	}
	
	//b0 = hcat(figures,top());
	
	//render(b0);
	
	//i = hcat([box(fillColor("red"),project(text(s),"hscreen")) | s <- ["a","b","c","d"]],top());
	//sc = hscreen(b0,id("hscreen"));
	//render(sc);
	
	tree1 = treemap(figures,fillColor("red"),area(10));
	tree2 = treemap(figures,fillColor("green"),area(15));
	tree3 = treemap(figures,fillColor("blue"),area(25));
	
	t = treemap([tree1,tree2,tree3]);
     
	render(t);
	
}

void ShowTreeMap(BrowsableMap myData)
{
	render(RenderTreeMap(myData));
}

Figure RenderTreeMap(BrowsableMap myData)
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
				println("topLostItem");
					
			return true;
			}));
	}

	return treemap(figureList,fillColor("red"));
}


Figure RenderTreeMap(BrowsableMap myData, BrowsableMap parent)
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
}

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



