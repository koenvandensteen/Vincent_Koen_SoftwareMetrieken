module View::TreeView

import vis::Figure;
import vis::Render;
import vis::KeySym;
import List;
import Set;
import Map;
import IO;
import util::Math;
import Helpers::DataContainers;
import Agregation::SIGRating;
import String;

/*
/ global vars
*/
private ProgramConfigs programConf = <false, false, false, false, "", "">; // program configuration
private map[tuple[str name, bool noTest] key, BrowsableMap mapData]  projectMap; // full projects
private list[str]projectList;
private [] Navigationquee;
private BrowsableMap HooveredItem;
private bool ObjectHighlighted = false;

/*
*	Visualisation control
*/
// enterance point and repainter
public void ShowGUI(map[tuple[str name, bool noTest] key, BrowsableMap mapData] projects)
{	
	// store project map and list
	projectMap = projects;
	set[str] tempList ={a.name | a <- domain(projects)};
	projectList = toList(tempList);
	
	//set starting configuration
	programConf.colorBlind = false;
	programConf.noTest = false;
	programConf.showDetails = false;
	programConf.aboutBox = false;
	programConf.currentMetric = "Overall";
		
	//select starting set
	setInputDataset(projectList[0], false);

}

// (re)paints the gui
private void RepaintGUI()
{
	render("SEVO",
		vcat(
			[
			ControlPanel(),
			DetailText(),			
			TitleBar(),
			RenderTreeMap()
			], gap(10)
		)
	);
}

/*
*	Figures
*/
// list for selecting the displayed rating
private Figure RatingSelection(){
  str state = "Overall";
  return vcat(
				[ choice(	["Overall","Lines of code","Unit size","Unit complexity","Duplication","Test coverage"], 
				void(str s){ 
					state = s; // from example
					programConf.currentMetric = s;
					RepaintGUI();
				}),
				box(text(str(){return "Selected metric: " + programConf.currentMetric ;},fontSize(10)),vshrink(0.2))
			],hshrink(0.25));
}

// list for selecting the displayed project
private Figure ProjectSelection(){
  str state = programConf.currentProject;
  return vcat(
				//[ combo(["JabberPoint","small sql","hsql"], void(str s){ state = s;}),text(str(){return "Current state: " + state ;}, left())]
				[ choice(projectList, void(str s){ 
					state = s; // from example
					// change current dataset
					setInputDataset(s, programConf.noTest);
				}),
				box(text(str(){return "Current project: " + state  ;},fontSize(10)),vshrink(0.2))
			],hshrink(0.25));
}

//display configuration, configuration is stored in a global variable
private Figure ConfigControls(){
	
	//location for export
	loc exloc = (|project://SoftwareEvolution/renders/|+programConf.currentProject)+(Navigationquee[size(Navigationquee)-1].abj.objName + "_" + programConf.currentMetric +".png");

	Color =  checkbox("Color blind mode",programConf[0],void(bool s){programConf.colorBlind = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
	NoTest =  checkbox("Ignore Junit",programConf[1],void(bool s){programConf.noTest = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
	Details = button("Details", void(){programConf.showDetails = !programConf.showDetails; RepaintGUI();},shadow(true),fillColor("LightGray"));
	Export = button("Export view", void(){renderSave(vcat([DetailText(),TitleBar(),RenderTreeMap()]),1920,1080,exloc);},shadow(true),fillColor("LightGray"));
	About = button("Info", void(){programConf.aboutBox = !programConf.aboutBox; RepaintGUI();},shadow(true),fillColor("LightGray"));
	
	return hcat([vcat([Color, NoTest]), Details, Export, About],hshrink(0.5));//,vshrink(0.1),gap(25));
}

// combine control components in one box
private Figure ControlPanel(){
	filters = RatingSelection();
	projects = ProjectSelection();
	configurations = ConfigControls();
	
	return hcat([filters, projects, configurations],vshrink(0.2),gap(20));
}

// horizontal bar containing the details for the selected object, or the about box
private Figure DetailText()
{
	if(programConf.showDetails && !(programConf.aboutBox))
	{
		output = "<HooveredItem.abj.objName> has the following metrics:\n";
		output += "Total lines of code = <HooveredItem.globalVars.lineCount> ";
		output += "Duplication percentage = <round(HooveredItem.globalVars.dupPercent*100.0,0.01)>% ";
		output += "Test coverage = <round(HooveredItem.globalVars.testPercent*100.0,0.01)>%\n";
		output += "Sig metrics: unit size: <transFormSIG(HooveredItem.rating.uLoc)> unit complexity: <transFormSIG(HooveredItem.rating.uComp)> Test coverage: <transFormSIG(HooveredItem.rating.uTest)> Duplication: <transFormSIG(HooveredItem.rating.uDup)>";

		return box(text(output),vshrink(0.1));
	}
	else if(!(programConf.aboutBox)){
		return box(text("No details to be shown"),vshrink(0.1));
	}
	else{
		output = "LMB: go into, RMB: show details\n";
		output += "Lists: The left list allows the user to select the metric he wishes to display, the list to the right selects the project.\n";
		output += "Checkboxes: \"Color blind mode\" will display all results in grayscale, ";
		output += "\"Ignore Junit\" will allow the user to not incorporate those results in the test. ";
		output += "Buttons: \"Export view\" will create a .png of the current view, \"Details\" toggles detailed view, \"Info\" shows this box! \nCreated by KVDS and VB";
		return box(text(output),fontSize(10),vshrink(0.1));
	}		
}

// title bar, contains the name of the current object
private Figure TitleBar()
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

// tree map figure
private Figure RenderTreeMap()
{
	figureList = [];
	
	// get grayscale or colored scale depending if the user checked the color blind box
	cscale = GetColorScale();

	for(myMapKey <-  Navigationquee[size(Navigationquee)-1].children)
	{
		thisObj =  Navigationquee[size(Navigationquee)-1].children[myMapKey];
		
		// get the rating we wish to evaluate
		thisObjScore = getRating(thisObj.rating, thisObj.globalVars);
		// create figure list
		figureList+=box(text(thisObj.abj.objName),fillColor(cscale(thisObjScore)),area(thisObj.globalVars.lineCount),	
			onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {		
				if(butnr==1 && thisObj.abj.objType != "method")
				{
					Navigationquee += thisObj;
					ObjectHighlighted = false;
					RepaintGUI();
				}		
				if(butnr==3)
				{				
					HooveredItem = thisObj;
					ObjectHighlighted = true;
					if(!programConf.showDetails)
						programConf.showDetails = true;
					RepaintGUI();
				}						
			return true;
			})
			);
	}

	return treemap(figureList,fillColor("red"),vshrink(0.6));
}

/*
* local elpers
*/
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
	ratings = [-3, -2, -1, 0, 1, 2];
		
	if(!programConf.colorBlind){
		return cscale = colorScale(ratings, color("red"),color("lime"));
	}
	else{
		return cscale = colorScale(ratings, color("black"),color("white"));
	}

}

// returns a single metric from the sig rating tuple, default value is de algemene sig rating
private int getRating(SIGRating rating, GlobalVars objVars){

	int volumeRating = GetSigRatingLOC(objVars.lineCount);

	switch(programConf.currentMetric){
		case "Overall":
			return GetTotalSIGRating(GetMaintabilityRating(volumeRating, rating.uComp, rating.uDup, rating.uLoc, rating.uTest));
		case "Lines of code":
			return volumeRating;
		case "Unit size":
			return(rating.uLoc);
		case "Unit complexity":
			return(rating.uComp);
		case "Duplication":
			return(rating.uDup);
		case "Test coverage":
			return(rating.uTest);
		default: 	
			return GetTotalSIGRating(GetMaintabilityRating(volumeRating, rating.uComp, rating.uDup, rating.uLoc, rating.uTest));
	}

}

