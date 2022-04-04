/// --- Initialize --- ///

if (isOpen("Log")) {selectWindow("Log"); run("Close");} 
if (isOpen("Summary")) {selectWindow("Summary"); run("Close");} 
if (isOpen("Results")) {selectWindow("Results"); run("Close");}
if (isOpen("ROI Manager")) {selectWindow("ROI Manager"); run("Close");}

list = getList("image.titles");
for (i=0; i<list.length; i++){
	if (endsWith(list[i], "C1-Mask.tif")==true){
		 C1_Mask = list[i];
	}
	if (endsWith(list[i], "C2-Mask.tif")==true){
		 C2_Mask = list[i];
	}
}

getPixelSize (unit, pixelWidth, pixelHeight);

/// --- Analyse objects --- ///

// C1 ------------------------------------------------------------------

selectWindow(C1_Mask);
run("Set Measurements...", "area centroid redirect=None decimal=3");
run("Analyze Particles...", "display add");

nObjects_C1 = nResults;
channel = newArray(nResults);
area = newArray(nResults);
xcoord = newArray(nResults);
ycoord = newArray(nResults);
ctrdval = newArray(nResults);
areafract = newArray(nResults);

for (i=0; i<nResults; i++){
	
	channel[i] = 1;
	area[i] = getResult("Area", i);
	xcoord[i] = getResult("X", i);
	ycoord[i] = getResult("Y", i);
	
	selectWindow(C2_Mask);
	
	ctrdval[i] = getValue(
		round(xcoord[i]/pixelWidth), 
		round(ycoord[i]/pixelWidth)
		)/255;			
}

run("Clear Results"); 

run("Set Measurements...", "area_fraction redirect=None decimal=3");
roiManager("Measure");
for (i=0; i<nResults; i++){
	areafract[i] = getResult("%Area", i);
}

run("Clear Results");

// C2 ------------------------------------------------------------------

selectWindow(C2_Mask);
run("Set Measurements...", "area centroid redirect=None decimal=3");
run("Analyze Particles...", "display add");

nObjects_C2 = nResults;

for (i=nObjects_C1+1; i<nObjects_C1+nObjects_C2; i++){
	
	channel[i] = 1;
	area[i] = getResult("Area", i);
	xcoord[i] = getResult("X", i);
	ycoord[i] = getResult("Y", i);
	
	selectWindow(C1_Mask);
	
	ctrdval[i] = getValue(
		round(xcoord[i]/pixelWidth), 
		round(ycoord[i]/pixelWidth)
		)/255;			
}

run("Clear Results"); 

run("Set Measurements...", "area_fraction redirect=None decimal=3");
roiManager("Measure");
for (i=nObjects_C1+1; i<nObjects_C1+nObjects_C2; i++){
	areafract[i] = getResult("%Area", i);
}

run("Clear Results");

/// --- Fill Result Table --- ///

for (i=0; i<nObjects_C1+nObjects_C2; i++) {
	setResult("channel",i,channel[i]);
	setResult("area",i,area[i]);
	setResult("xcoord",i,xcoord[i]);
	setResult("ycoord",i,ycoord[i]);
	setResult("ctrdval",i,ctrdval[i]);
	setResult("areafract",i,areafract[i]);
}
setOption("ShowRowNumbers", false);
updateResults;

stop
