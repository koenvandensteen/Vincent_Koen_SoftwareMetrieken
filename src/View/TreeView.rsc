module View::TreeView

import vis::Figure;
import vis::Render;
/*
import vis::treemap;
import vis::button;
import vis::vcat;
import vis::hcat;
*/
import vis::KeySym;
import List;
import Map;
import IO;
import Helpers::DataContainers;
import Agregation::SIGRating;

import String;

//alias projectPart = lrel[int linesOfCode,sigRating rating,map[string, projectPart] content, bool render];
//alias sigRating = lrel[int size,int duplication,int complexity,int unitSize, int unitTest];

//alias AnalyzedObject = tuple[str objName, str objType];
//data TreeMap = treeMap(loc location, AnalyzedObject abj, SIGRating rating, map[loc,TreeMap] children,int cl, bool render);
//alias SIGRating = tuple[int uLoc, int uComp, int uDup, int uTest];

/* new */
	// global vars
	ProgramConfigs programConf = <false, false, false, "", "">; // program configuration
	map[tuple[str name, bool noTest] key, BrowsableMap mapData]  projectMap; // full projects
	//map[tuple[loc location, bool noTest], str name] projectMap; // full projects
	list[str] projectList; // project names
	//str currentProject; // current project name
	//str currentMetric; // metric currently displayed
/* end new */

[] Navigationquee;

BrowsableMap HooveredItem;

SigFilter SelectedFilter;
bool ObjectHighlighted = false;

//alias SigFilter = lrel[bool Loc, bool Comp, bool Dupl, bool Test];

void main()
{

}

/* replaced
	Figure FilterBoxes()
	{
		Loc =  checkbox("Lines of Code",void(bool s){SelectedFilter.Loc = s;},shadow(true),fillColor("LightGray"));
		Comp =  checkbox("Complexity",void(bool s){SelectedFilter.Comp = s;},shadow(true),fillColor("LightGray"));
		Dupl =  checkbox("Duplication",void(bool s){SelectedFilter.Dupl = s;},shadow(true),fillColor("LightGray"));
		Test =  checkbox("Test",void(bool s){SelectedFilter.Test = s;},shadow(true),fillColor("LightGray"));

		return hcat([Loc,Comp,Dupl,Test],vshrink(0.1),gap(25));
	}
end replaced */

/* replaced
	Figure DetailText()
	{
		if(ObjectHighlighted)
		{
			return box(text(HooveredItem.abj.objName),vshrink(0.2));
		}
		else
		{
			return box(text("No details to be shown"),vshrink(0.2));
		}
			
		
	}
end replaced */

/* new */
	Figure DetailText()
	{
		if(ObjectHighlighted && !(programConf.aboutBox))
		{
			return box(text(HooveredItem.abj.objName),vshrink(0.1));
		}
		else if(!(programConf.aboutBox)){
			return box(text("No details to be shown"),vshrink(0.1));
		}
		else{
			return box(text("To do: add some details of how this tool works, what the colours mean etc."),vshrink(0.1));
		}		
	}
/* end new */

Figure TitleBar()
{
	barItems = [box(text("<Navigationquee[size(Navigationquee)-1].abj.objName>",fontSize(20)))];

	if(size(Navigationquee)>1)
	{
		barItems = insertAt(barItems,0,
			button("Go back to <Navigationquee[size(Navigationquee)-2].abj.objType>-View",
			void(){
				Navigationquee = delete(Navigationquee,size(Navigationquee)-1);
				ObjectHighlighted = false;
				RepaintGUI();
			}
		,hshrink(0.2)));
	}
	
	return box(hcat(barItems),vshrink(0.1));
}

/* new */
	// rating selection
	private Figure RatingSelection(){
	  str state = "Overall";
	  return vcat(
					[ choice(["Overall","Lines of code","Unit size","Unit complexity","Duplication","Test coverage"], 
					void(str s){ 
						state = s; // from example
						programConf.currentMetric = s;
						RepaintGUI();
					})//,
					//text(str(){return "Currently displaying: " + state ;}, left())
				]);
	}

	//project selection
	private Figure ProjectSelection(){
	  str proj = programConf.currentProject;
	  // make the options based on the project list
	  return vcat(
					//[ combo(["JabberPoint","small sql","hsql"], void(str s){ state = s;}),text(str(){return "Current state: " + state ;}, left())]
					[ choice(projectList, void(str s){ 
						state = s; // from example
						// change current dataset
						setInputDataset(s, programConf.noTest);
					})//,
					//text(str(){return "Current project: " + proj ;}, left())
				]);
	}

	//display configuration, configuration is stored in a global variable
	Figure ConfigControls(){
		Color =  checkbox("Color blind mode",void(bool s){programConf.colorBlind = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
		NoTest =  checkbox("Ignore junit test",void(bool s){programConf.noTest = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
		About = button("Toggle about", void(){programConf.aboutBox = !programConf.aboutBox; RepaintGUI();},shadow(true),fillColor("LightGray"));
		
		return hcat([Color, NoTest, About]);//,vshrink(0.1),gap(25));
	}

	// combine control components in one box
	Figure ControlPanel(){
		filters = RatingSelection();
		projects = ProjectSelection();
		configurations = ConfigControls();
		
		//return hcat([filters, projects, configurations],vshrink(0.1),gap(25));
		return hcat([filters, projects, configurations],vshrink(0.2),gap(25));
	}
/* end new */

/* replaced 
	void ShowGUI(BrowsableMap myData)
	{
		//AllData = myData;
		//SelectedItem = myData;
		
		Navigationquee = [myData];
		HooveredItem = myData;
		
		render(
			vcat(
				[
				FilterBoxes(),
				DetailText(),			
				TitleBar(),
				RenderTreeMap()
				], gap(10)
			)
		);
	}
 end replaced */ 

/* new */
// enterance point and repainter
	public void ShowGUI(map[tuple[str name, bool noTest] key, BrowsableMap mapData] projects)
	{	
		// store project map and list
		projectMap = projects;
		projectList = [a.name | a <- domain(projects)];
		
		//set starting configuration
		programConf.colorBlind = false;
		programConf.noTest = false;
		programConf.aboutBox = false;
		programConf.currentMetric = "Overall";
			
		//select starting set
		setInputDataset(projectList[0], false);

	}
/* end new */

void RepaintGUI()
{
	render("SEVO",
		vcat(
			[
			/* replaced
			FilterBoxes(),
			end replaced */
			/* new */
			ControlPanel(),
			//ComboRating(),
			//ProjectSelection(),
			//ConfigControls(),
			/* end new */
			DetailText(),			
			TitleBar(),
			RenderTreeMap()
			], gap(10)
		)
	);
}


Figure RenderTreeMap()
{
	figureList = [];
	
	// get grayscale or colored scale depending if the user checked the color blind box
	cscale = GetColorScale();
	

	for(myMapKey <-  Navigationquee[size(Navigationquee)-1].children)
	{
		thisObj =  Navigationquee[size(Navigationquee)-1].children[myMapKey];
		
		/* new */
		// get the rating we wish to evaluate
		thisObjScore = getRating(thisObj.rating, thisObj.globalVars);
		/* end new */
		
		//println("My Map Key: <myMapKey>");
		//println("MyMap Name: <thisObj.abj.objName> with children <thisObj.children>");
		/* replaced
			figureList+=box(text(thisObj.abj.objName),fillColor(GetRatingColor(thisObj.rating)),area(thisObj.globalVars.lineCount),
		end replaced */
		/* new */
			figureList+=box(text(thisObj.abj.objName),fillColor(cscale(thisObjScore)),area(thisObj.globalVars.lineCount),	
		/* end new */
			onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
			
			if(butnr==1)
			{
				Navigationquee += thisObj;
				RepaintGUI();
			}
	
			if(butnr==3)
			{				
				HooveredItem = thisObj;
				ObjectHighlighted = true;
				RepaintGUI();
			}
					
			return true;
			})
			);
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

/* new */
	// sets the current working project
	private void setInputDataset(str name, bool noTest){
		programConf.currentProject = name;
		HooveredItem = projectMap[<name, noTest>];
		Navigationquee = [HooveredItem];
		RepaintGUI();
	}

	// gets a color scale based on the setting colorblind
	private Color(num) GetColorScale()
	{
		ratings = [-2, -1, 0, 1, 2];
			
		if(!programConf.colorBlind){
			return cscale = colorScale(ratings, color("red"),color("green"));
		}
		else{
			return cscale = colorScale(ratings, color("black"),color("white"));
		}

	}
	
	// returns a single int from the sig rating tuple
	private int getRating(SIGRating rating, GlobalVars objVars){
	
		int volumeRating = GetSigRatingLOC(objVars.lineCount);
	
		switch(programConf.currentMetric){
			case "Overall":
				return GetTotalSIGRating(GetMaintabilityRating(volumeRating, rating.uComp, rating.uDup, rating.uLoc, rating.uTest));
			case "Lines of code":
				return volumeRating;
			case "Complexity":
				return(rating.uLoc);
			case "Complexity":
				return(rating.uComp);
			case "Duplication":
				return(rating.uDup);
			case "Test coverage":
				return(rating.uTest);
			default: 	
				return GetTotalSIGRating(GetMaintabilityRating(volumeRating, rating.uComp, rating.uDup, rating.uLoc, rating.uTest));
		}
	
	}
/* end new */
