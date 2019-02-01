module View::TreeView

import vis::Figure;
import vis::Render;
import vis::KeySym;
import List;
import Set;
import Map;
import IO;
import Helpers::DataContainers;
import Agregation::SIGRating;

import String;

// global vars
ProgramConfigs programConf = <false, false, false, "", "">; // program configuration
map[tuple[str name, bool noTest] key, BrowsableMap mapData]  projectMap; // full projects
list[str]projectList;
[] Navigationquee;
BrowsableMap HooveredItem;
bool ObjectHighlighted = false;


Figure DetailText()
{
	if(ObjectHighlighted && !(programConf.aboutBox))
	{
		output = "<HooveredItem.abj.objName> has the following metrics:\n";
		output += "Total lines of code = <HooveredItem.globalVars.lineCount> ";
		output += "Duplication percentage = <HooveredItem.globalVars.dupPercent> ";
		output += "Test coverage = <HooveredItem.globalVars.testPercent>\n";
		output += "Sig metrics: unit size: <transFormSIG(HooveredItem.rating.uLoc)> unit complexity: <transFormSIG(HooveredItem.rating.uComp)> Test coverage: <transFormSIG(HooveredItem.rating.uTest)> Duplication: <transFormSIG(HooveredItem.rating.uDup)>";

		return box(text(output),vshrink(0.1));
	}
	else if(!(programConf.aboutBox)){
		return box(text("No details to be shown"),vshrink(0.1));
	}
	else{
		return box(text("LMB: go into, RMB: show details\nLists: The left list allows the user to select the metric he wishes to display, the list to the right selects the project.\nCheckboxes: Color blind mode will display all results in grayscale, the ignore unit tests will allow the user to not incorporate those results in the test.Buttons: export view will create a .png of the current view, toggle about shows this box! \nCreated by KVDS and VB"),vshrink(0.1));
	}		
}


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
			],hshrink(0.20));
}

//project selection
private Figure ProjectSelection(){
  str state = programConf.currentProject;
  // make the options based on the project list
  return vcat(
				//[ combo(["JabberPoint","small sql","hsql"], void(str s){ state = s;}),text(str(){return "Current state: " + state ;}, left())]
				[ choice(projectList, void(str s){ 
					state = s; // from example
					// change current dataset
					setInputDataset(s, programConf.noTest);
				})//,
				//text(str(){return "Current project: " + proj ;}, left())
			],hshrink(0.20));
}

//display configuration, configuration is stored in a global variable
Figure ConfigControls(){
	
	//location for export
	loc exloc = (|project://SoftwareEvolution/renders/|+programConf.currentProject)+(Navigationquee[size(Navigationquee)-1].abj.objName + ".png");

	Color =  checkbox("Color blind mode",void(bool s){programConf.colorBlind = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
	NoTest =  checkbox("Ignore junit test",void(bool s){programConf.noTest = s; RepaintGUI();},shadow(true),fillColor("LightGray"));
	About = button("Toggle about", void(){programConf.aboutBox = !programConf.aboutBox; RepaintGUI();},shadow(true),fillColor("LightGray"));
	Export = button("Export view", void(){renderSave(vcat([DetailText(),TitleBar(),RenderTreeMap()]),1920,1080,exloc);},shadow(true),fillColor("LightGray"));
	
	return hcat([Color, NoTest, Export, About],hshrink(0.6));//,vshrink(0.1),gap(25));
}

// combine control components in one box
Figure ControlPanel(){
	filters = RatingSelection();
	projects = ProjectSelection();
	configurations = ConfigControls();
	
	return hcat([filters, projects, configurations],vshrink(0.2),gap(20));
}

// enterance point and repainter
public void ShowGUI(map[tuple[str name, bool noTest] key, BrowsableMap mapData] projects)
{	
	// store project map and list
	projectMap = projects;
	set[str] tempList ={a.name | a <- domain(projects)};
	projectList = toList(tempList);
	
	//debug
	println(projectList);
	
	//set starting configuration
	programConf.colorBlind = false;
	programConf.noTest = false;
	programConf.aboutBox = false;
	programConf.currentMetric = "Overall";
		
	//select starting set
	setInputDataset(projectList[0], false);

}

// (re)paints the gui
void RepaintGUI()
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


Figure RenderTreeMap()
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

