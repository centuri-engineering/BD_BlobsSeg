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
run("Invert");
run("Set Measurements...", "area centroid redirect=None decimal=3");
run("Analyze Particles...", "display add"); roiManager("Show None");

C1_nObjects = nResults;
C1_channel = newArray(nResults);
C1_area = newArray(nResults);
C1_xcoord = newArray(nResults);
C1_ycoord = newArray(nResults);
C1_ctrdval = newArray(nResults);
C1_areafract = newArray(nResults);

for (i=0; i<nResults; i++){
	
	C1_channel[i] = 1;
	C1_area[i] = getResult("Area", i);
	C1_xcoord[i] = getResult("X", i);
	C1_ycoord[i] = getResult("Y", i);
	
	selectWindow(C2_Mask);
	
	C1_ctrdval[i] = getValue(
		round(C1_xcoord[i]/pixelWidth), 
		round(C1_ycoord[i]/pixelWidth)
		)/255;			
}

run("Clear Results"); 

run("Set Measurements...", "area_fraction redirect=None decimal=3");
roiManager("Measure");
for (i=0; i<nResults; i++){
	C1_areafract[i] = getResult("%Area", i);
}
roiManager("reset") 

run("Clear Results");
selectWindow(C1_Mask);
run("Invert");

// C2 ------------------------------------------------------------------

selectWindow(C2_Mask);
run("Invert");
run("Set Measurements...", "area centroid redirect=None decimal=3");
run("Analyze Particles...", "display add"); roiManager("Show None");

C2_nObjects = nResults;
C2_channel = newArray(nResults);
C2_area = newArray(nResults);
C2_xcoord = newArray(nResults);
C2_ycoord = newArray(nResults);
C2_ctrdval = newArray(nResults);
C2_areafract = newArray(nResults);

for (i=0; i<nResults; i++){
	
	C2_channel[i] = 2;
	C2_area[i] = getResult("Area", i);
	C2_xcoord[i] = getResult("X", i);
	C2_ycoord[i] = getResult("Y", i);
	
	selectWindow(C1_Mask);
	
	C2_ctrdval[i] = getValue(
		round(C2_xcoord[i]/pixelWidth), 
		round(C2_ycoord[i]/pixelWidth)
		)/255;			
}

run("Clear Results"); 

run("Set Measurements...", "area_fraction redirect=None decimal=3");
roiManager("Measure");
for (i=0; i<nResults; i++){
	C2_areafract[i] = getResult("%Area", i);
}
roiManager("reset") 

run("Clear Results");
selectWindow(C2_Mask);
run("Invert");


/// --- Get general stats --- ///

imageCalculator("AND create", C1_Mask,C2_Mask);
rename("C1C2_inter"); C1C2_inter = getTitle();
imageCalculator("OR create", C1_Mask,C2_Mask);
rename("C1C2_union"); C1C2_union = getTitle(); 

run("Set Measurements...", "integrated redirect=None decimal=3");

selectWindow(C1_Mask);
run("Select All"); run("Measure");
C1_area_val = getResult("RawIntDen", 0)/255;
run("Clear Results");
run("Select None");

selectWindow(C2_Mask);
run("Select All"); run("Measure");
C2_area_val = getResult("RawIntDen", 0)/255;
run("Clear Results");
run("Select None");

selectWindow(C1C2_inter);
run("Select All"); run("Measure");
C1C2_inter_val = getResult("RawIntDen", 0)/255;
run("Clear Results");
close(C1C2_inter);

selectWindow(C1C2_union);
run("Select All"); run("Measure");
C1C2_union_val = getResult("RawIntDen", 0)/255;
run("Clear Results");
close(C1C2_union);

C1C2_IoU_val = C1C2_inter_val/C1C2_union_val;

Array.getStatistics(C1_ctrdval, min, max, mean, std);
Avg_C1_ctrdval = mean;
Array.getStatistics(C1_areafract, min, max, mean, std);
Avg_C1_areafract = mean;
Array.getStatistics(C2_ctrdval, min, max, mean, std);
Avg_C2_ctrdval = mean;
Array.getStatistics(C2_areafract, min, max, mean, std);
Avg_C2_areafract = mean;

/// --- Fill Summary --- ///

Table.create("Summary");
Table.set("C1_area", 0, C1_area_val);
Table.set("C2_area", 0, C2_area_val);

Table.set("Avg_C1_ctrdval", 0, Avg_C1_ctrdval);
Table.set("Avg_C1_areafract", 0, Avg_C1_areafract);
Table.set("Avg_C2_ctrdval", 0, Avg_C2_ctrdval);
Table.set("Avg_C2_areafract", 0, Avg_C2_areafract);

Table.set("C1C2_union", 0, C1C2_union_val);
Table.set("C1C2_inter", 0, C1C2_inter_val);
Table.set("C1C2_IoU", 0, C1C2_IoU_val);

stop

/// --- Fill Result Table --- ///

All_channel = Array.concat(C1_channel,C2_channel);
All_area = Array.concat(C1_area,C2_area);
All_xcoord = Array.concat(C1_xcoord,C2_xcoord);
All_ycoord = Array.concat(C1_ycoord,C2_ycoord);
All_ctrdval = Array.concat(C1_ctrdval,C2_ctrdval);
All_areafract = Array.concat(C1_areafract,C2_areafract);

for (i=0; i<All_channel.length; i++) {
	setResult("channel",i,All_channel[i]);
	setResult("area",i,All_area[i]);
	setResult("xcoord",i,All_xcoord[i]);
	setResult("ycoord",i,All_ycoord[i]);
	setResult("ctrdval",i,All_ctrdval[i]);
	setResult("areafract",i,All_areafract[i]);
}
setOption("ShowRowNumbers", false);
updateResults;






