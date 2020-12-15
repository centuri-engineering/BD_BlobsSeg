/// --- Initialize --- ///
if (isOpen("ROI Manager")) {
	selectWindow("ROI Manager");
	run("Close");
}
run("ROI Manager...");

setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);

/// --- Dialog --- ///
Dialog.create("BlobsSeg-Options");
nChannel = Dialog.addChoice("Specify Channel:", newArray("C1", "C2", "C3", "C4"));
ThreshCoeff = Dialog.addNumber("Tresh. Coeff. (big objects)", 1);
MinSize = Dialog.addNumber("Min. Size (for big objects)", 15);

Dialog.show();

nChannel = Dialog.getChoice();
ThreshCoeff = Dialog.getNumber();
MinSize = Dialog.getNumber();

/// --- Open & get variables --- ///
nameczi = getTitle();
name = File.nameWithoutExtension;
getDimensions(width,height,channels,slices,frames);

Chn = nameczi; 
if (channels > 1){run("Split Channels");
Chn = nChannel+"-"+nameczi;}
C1 = "C1-"+nameczi;
C2 = "C2-"+nameczi;
C3 = "C3-"+nameczi;
C4 = "C4-"+nameczi;
selectWindow(Chn);
rename("Chn"); Chn = getTitle();
nameroi = name + ".roi"; 
namezip = name + ".zip"; 
folder = File.directory;
list = getFileList(folder);

setBatchMode(true);

/// --- Check wether ROI(s) in .roi or .zip file --- ///
testroi = 0;testzip = 0;
	for(file=0; file<list.length; file++){
		if (indexOf(list[file],nameroi)>=0){
			testroi = 1;
		} else { testroi = testroi; }
		if (indexOf(list[file],namezip)>=0){
			testzip = 1;
		} else { testzip = testzip; }
	}

/// --- Open ROI(s) --- ///
if (testroi == 1){
open(folder+name+".roi");
roiManager("Add");
run("Select None");}

if (testzip == 1){
open(folder+name+".zip");
roiManager("Combine");
roiManager("Add");
run("Select None");
}
nROIs = roiManager("count")-1;

/// --- Measure Total Area (within ROI(s)) --- ///
roiManager("Select", nROIs);
roiManager("Measure");
ROIsArea = getResult("Area",0);
run("Select None");

/// --- Remove Outliers --- ///
selectWindow(Chn);
run("Duplicate...", " ");
rename("ChnBG"); ChnBG = getTitle();
run("Remove Outliers...", "radius=30 threshold=30 which=Bright");
imageCalculator("Subtract create", Chn,ChnBG);
roiManager("Select", nROIs);
run("Clear Outside");
run("Select None");
run("Gaussian Blur...", "sigma=1");
rename("ChnProcess"); ChnProcess = getTitle();

/// --- Measure Background --- ///
run("Set Measurements...", "area mean redirect=None decimal=3");
selectWindow(ChnBG);
roiManager("Select", nROIs);
roiManager("Measure");
BgChn = getResult("Mean", 0);
ThreshChn = BgChn*ThreshCoeff;
close(ChnBG);

/// --- Make Masks&Outlines (strong signal) --- ///
selectWindow(ChnProcess);
setThreshold(ThreshChn, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Analyze Particles...", "size="+MinSize+"-Infinity pixel show=Masks display add");
run("Invert LUT"); /// !!!
rename("ChnMask"); ChnMask = getTitle(); 
run("Duplicate...", " ");
run("Outline");
rename("ChnMaskOutlines"); ChnMaskOutlines = getTitle();

/// --- Close Data --- ///
close(C1);close(C2);close(C3);close(C4);
close(ChnBG);close(ChnProcess);
selectWindow("ROI Manager"); run("Close");
selectWindow("Results"); run("Close");

/// --- Measure big blobs --- ///
selectWindow("ChnMask");
run("Set Measurements...", "area mean shape feret's area_fraction redirect=None decimal=3");
run("Analyze Particles...", "size=0.00-Infinity show=Masks display summarize add in_situ");
run("Remove Overlay");

/// --- Update&Show Results --- ///
run("Merge Channels...", "c7=ChnMaskOutlines c4=Chn create");

selectWindow("Summary");
ObjectAvgSize = d2s(Table.get("Average Size", 0),3);
TotalObjectArea = (Table.get("Count", 0)) * (Table.get("Average Size", 0)); 
percentArea = (TotalObjectArea/ROIsArea)*100;

Table.set("Slice", 0, name);
Table.renameColumn("Slice", "Image Name")
Table.renameColumn("Total Area", "Total ROI(s) Area")
Table.renameColumn("Average Size", "Total Object Area")
Table.renameColumn("Mean", "Avg Size")

Table.set("Slice", 0, name);
Table.set("Total ROI(s) Area", 0, ROIsArea);
Table.set("Total Object Area", 0, TotalObjectArea);
Table.set("%Area", 0, percentArea);
Table.set("Avg Size", 0, ObjectAvgSize);

Table.deleteColumn("Slice")
Table.update;

setBatchMode("exit and display");
run("Tile");
selectWindow("Results");
selectWindow("Summary");

/// --- Close all --- ///
waitForUser( "Pause","Click Ok when finished");
macro "Close All Windows" { 
while (nImages>0) { 
selectImage(nImages); 
close();
}
if (isOpen("Log")) {selectWindow("Log"); run("Close");} 
if (isOpen("Summary")) {selectWindow("Summary"); run("Close");} 
if (isOpen("Results")) {selectWindow("Results"); run("Close");}
if (isOpen("ROI Manager")) {selectWindow("ROI Manager"); run("Close");}
} 
