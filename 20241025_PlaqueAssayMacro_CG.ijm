// Author: Christian Gnann
// imageJ Macro for the Analysis of a toxoplasma plaque assay --> Plaqro
// just some parameters; change the suffix depending on the file ending you have in your data
delimiter = "."; 
suffix = ".tif";

// Asks for input directory first
input = getDirectory("Input directory"); // specify where the images are located --> pop up window
// Asks for output directory second
output = getDirectory("Output directory"); // specify where the results should be saved

// pop up window that will allow you to rename the output file according to the condition used 
condition = getString("Set a condition that you will use for saving; e.g. PlaqueAssay_MYR1_KO","");
date = "20241025"
threshold_low = 158 //threshold that seemed to work for most iages; can use this to manually set the theshold instead
// pop up window that will allow you to input the markers in the images

run("Clear Results"); //cleans all possible mesaurements from previous analysis

processFolder(input);
print("Finished Processing");

// function to scan folders/subfolders/files to find files with correct suffix --> i.e. all the images in the folder
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			if(!endsWith(list[i], "raw16" + suffix)) //only process regular tiff images and ignore the .raw16.tif files
				processFile(input, output, list[i]);
			
	}
}

// actual run function
function processFile(input, output, file) {
	// open the image
	original_filename = input + file;
    filewosuffix = replace(file, suffix, "");
    print("Processing: " + original_filename);
    open(original_filename);

    // clear rois from previous image
    if (isOpen("ROI Manager")) {  //closes rpi manager and removes areas of interest from previous analysis
		selectWindow("ROI Manager");
		run("Close");
	}
	roiManager("Deselect");
	
	// convert to 8 bit image
	run("8-bit");
	// crop the image
	makeRectangle(486, 376, 502, 498);
	waitForUser("Move the rectange to desired postion");
	run("Crop");
	
	// Adjust the treshold and identify individual plaques
	run("Duplicate...", " "); // so you have the original image to compare to
	run("Gaussian Blur...", "sigma=2"); //Blur to get better objects
	setAutoThreshold("Yen dark");; // this thresholding method worked good for most images
	// alternatively manual threshold
	// setThreshold(threshold_low, 255, "raw");
	waitForUser("check whether you are happy with the threshold; otherwise change it by moving the slider and click 'Set'");
	run("Convert to Mask");
	run("Watershed"); // to separate connected objects
	run("Analyze Particles...", "size=0.0003-Infinity exclude include add"); // change the threshold if you are not happy with this
	waitForUser("double check the segmentations and adjust/manually add to the roi manager if you want"); // change the threshold if you are not happy with this
	
	// now run the measurements and export the results table as a 
	run("Set Measurements...", "area display redirect=None decimal=6");
	roiManager("Show All");
	roiManager("Measure");
	// save the results table; label = filename containing all the conditions, ...
	// resultstable will be overwritten in every cycle
	saveAs("Results", output +  date + "_" + condition + "_results.csv");
	
	// close the images
	close();
	close();
}
// to prevent running out of memory
run("Close All"); 
call("java.lang.System.gc");